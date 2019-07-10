class Withdraw < ActiveRecord::Base
  STATES = [:submitting, :submitted, :rejected, :pending, :suspect, :processing,
            :done, :canceled, :almost_done, :failed]
  COMPLETED_STATES = [:done, :rejected, :canceled, :almost_done, :failed]
  DONE_STATES = [:pending, :processing, :almost_done, :done]

  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible
  # added when removing Withdraws::{CoinName}
  include Withdraws::Coinable
  include FundSourceable

  has_paper_trail on: [:update, :destroy]

  enumerize :aasm_state, in: STATES, scope: true

  belongs_to :member
  belongs_to :account
  has_many :account_versions, as: :modifiable

  delegate :balance, to: :account, prefix: true
  delegate :name, to: :member, prefix: true
  delegate :coin?, :fiat?, to: :currency_obj

  before_validation :fix_precision
  before_validation :calc_fee
  before_validation :set_account
  after_create :generate_sn

  validates_with WithdrawBlacklistValidator

  validates :fund_uid, :amount, :fee, :account, :currency, :member, presence: true

  validates :fee, numericality: {greater_than_or_equal_to: 0}
  validates :amount, numericality: {greater_than: 0}

  validates :sum, presence: true, numericality: {greater_than: 0}, on: :create
  validates :txid, uniqueness: true, allow_nil: true, on: :update

  validate :check_min_amount, on: :create
  validate :ensure_account_balance, on: :create

  scope :completed, -> { where aasm_state: COMPLETED_STATES }
  scope :not_completed, -> { where.not aasm_state: COMPLETED_STATES }
  scope :done, -> {where aasm_state: DONE_STATES}

  scope :h24, -> {where("created_at > ?", 24.hours.ago)}

  alias_attribute :withdraw_id, :sn
  alias_attribute :full_name, :member_name

  def generate_sn
    id_part = sprintf '%04d', id
    date_part = created_at.localtime.strftime('%y%m%d%H%M')
    self.sn = "#{date_part}#{id_part}"
    update_column(:sn, sn)
  end

  aasm :whiny_transitions => false do
    state :submitting,  initial: true
    state :submitted,   after_commit: :send_email
    state :canceled,    after_commit: [:send_email]
    state :pending
    state :suspect,     after_commit: :send_email
    state :rejected,    after_commit: :send_email
    state :processing,  after_commit: [:send_coins!, :send_email]
    state :almost_done
    state :done,        after_commit: [:send_email, :send_sms]
    state :failed,      after_commit: :send_email

    event :submit do
      transitions from: :submitting, to: :submitted
      after do
        lock_funds
      end
    end

    event :cancel do
      transitions from: [:submitting, :submitted, :pending], to: :canceled
      after do
        after_cancel
      end
    end

    event :mark_suspect do
      transitions from: [:submitted, :pending, :processing], to: :suspect
    end

    event :accept do
      transitions from: :submitted, to: :pending
    end

    event :reject do
      transitions from: [:submitted, :pending, :suspect, :processing], to: :rejected
      after :unlock_funds
    end

    event :process do
      transitions from: [:pending, :suspect], to: :processing
    end

    event :call_rpc do
      transitions from: :processing, to: :almost_done
    end

    event :succeed do
      transitions from: [:processing, :almost_done], to: :done

      before [:set_txid, :unlock_and_sub_funds]
    end

    event :fail do
      transitions from: :processing, to: :failed
      after :unlock_funds
    end
  end

  def cancelable?
    submitting? or submitted? or pending?
  end

  def quick?
    sum <= currency_obj.quick_withdraw_max
  end

  def audit!
    with_lock do
      if account.examine
        accept
        process if quick?
      else
        mark_suspect
      end

      save!
    end
  end

  private

  def after_cancel
    unlock_funds unless aasm.from_state == :submitting
  end

  def lock_funds
    account.lock!
    account.lock_funds sum, reason: Account::WITHDRAW_LOCK, ref: self
  end

  def unlock_funds
    account.lock!
    account.unlock_funds sum, reason: Account::WITHDRAW_UNLOCK, ref: self
  end

  def unlock_and_sub_funds
    account.lock!
    account.unlock_and_sub_funds sum, locked: sum, fee: fee, reason: Account::WITHDRAW, ref: self
  end

  def set_txid
    self.txid = @sn unless coin?
  end

  def send_email
    case aasm_state
    when 'submitted'
      WithdrawMailer.submitted(self.id).deliver
    when 'processing'
      WithdrawMailer.processing(self.id).deliver
    when 'done'
      WithdrawMailer.done(self.id).deliver
    else
      WithdrawMailer.withdraw_state(self.id).deliver
    end
  end

  def send_sms
    return true if not member.sms_two_factor.activated?

    sms_message = I18n.t('sms.withdraw_done', email: member.email,
                                              currency: currency_text,
                                              time: I18n.l(Time.now),
                                              amount: amount,
                                              balance: account.balance)

    AMQPQueue.enqueue(:sms_notification, phone: member.phone_number, message: sms_message)
  end

  def send_coins!
    AMQPQueue.enqueue(:withdraw_coin, id: id) if coin?
  end

  def ensure_account_balance
    if sum.nil? or sum > account.balance
      errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
    end
  end

  def fix_precision
    if sum && currency_obj.precision
      self.sum = sum.round(currency_obj.precision, BigDecimal::ROUND_DOWN)
    end
  end

  def check_min_amount
    if self.sum < (currency_obj.withdraw['min_amount'] || 0)
      errors.add :base, -> {"Amount should be larger than minimum limit."}
    end
  end

  def calc_fee
    self.sum ||= 0.0
    self.fee = currency_obj.withdraw['fee'] || 0
    self.amount = sum - fee
  end

  def set_account
    self.account = member.get_account(currency)
  end

  def self.resource_name
    name.demodulize.underscore.pluralize
  end

end
