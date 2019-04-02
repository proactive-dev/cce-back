class PaymentTransaction < ActiveRecord::Base
  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible

  STATE = [:unconfirm, :confirming, :confirmed]
  enumerize :aasm_state, in: STATE, scope: true

  validates_presence_of :txid

  has_one :deposit
  belongs_to :payment_address, touch: true
  has_one :account, through: :payment_address
  has_one :member, through: :account

  aasm :whiny_transitions => false do
    state :unconfirm, initial: true
    state :confirming, after_commit: :deposit_accept
    state :confirmed, after_commit: :deposit_accept

    event :check do |e|
      before :refresh_confirmations

      transitions :from => [:unconfirm, :confirming], :to => :confirming, :guard => :min_confirm?
      transitions :from => [:unconfirm, :confirming, :confirmed], :to => :confirmed, :guard => :max_confirm?
    end
  end

  def min_confirm?
    deposit.min_confirm?(confirmations)
  end

  def max_confirm?
    deposit.max_confirm?(confirmations)
  end

  def refresh_confirmations
    make_deposit unless deposit

    update!(confirmations: CoinAPI[deposit.currency].load_deposit!(txid).fetch(:confirmations))
  end

  def deposit_accept
    if deposit.may_accept?
      deposit.accept! 
    end
  end

  def make_deposit
    unless self.deposit

      self.deposit = Deposit.create! \
        payment_transaction_id: self.id,
        txid:                   self.txid,
        txout:                  self.txout,
        amount:                 self.amount,
        member:                 self.member,
        currency:               self.currency,
        confirmations:          self.confirmations

      self.deposit.with_lock do
        self.deposit.submit!
        self.deposit.save!
      end
    end
  end

end
