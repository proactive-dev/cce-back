class OpenLoan < ActiveRecord::Base
  extend Enumerize

  enumerize :currency, in: LoanMarket.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0, :matched => 300, :reject => 400}, scope: true

  SOURCES = %w(Web APIv2 debug)
  enumerize :source, in: SOURCES, scope: true

  after_commit :trigger
  before_validation :fix_number_precision, on: :create

  validates_presence_of :amount, :origin_amount
  validates_numericality_of :origin_amount, :greater_than => 0

  validates_numericality_of :rate, greater_than: 0, allow_nil: false

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'
  REJECT = 'reject'
  MATCHED = 'matched'

  ATTRIBUTES = %w(id loan_market kind rate amount origin_amount duration auto_renew state state_text at)

  belongs_to :member
  attr_accessor :total

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :position, -> { group("rate").pluck(:rate, 'sum(amount)') }

  def funds_used
    origin_amount - amount
  end

  def fee
    config[:fee]
  end

  def config
    @config ||= LoanMarket.find(currency)
  end

  def hold_account
    member.get_account(currency)
  end

  def hold_margin_account
    member.get_margin_account(currency)
  end

  def hold_lending_account
    member.get_lending_account(currency)
  end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end
    member.trigger('open_loan', json)
  end

  def strike(active_loan)
    raise "Cannot strike on cancelled or done loan. id: #{id}, state: #{state}" unless state == OpenLoan::WAIT

    lending_amount = active_loan.amount
    case self.kind
      when 'demand'
        hold_margin_account.plus_borrowed lending_amount, reason: MarginAccount::LOAN_MATCHED, ref: active_loan
        trigger_order.fill(lending_amount) if trigger_order
      when 'offer'
        hold_lending_account.unlock_funds lending_amount, reason: LendingAccount::LOAN_MATCHED, ref: active_loan
    end

    self.amount         -= lending_amount
    self.funds_received += lending_amount
    self.active_loans_count   += 1

    self.state = OpenLoan::DONE if amount.zero?

    self.save!
  end

  def unstrike(active_loan)
    lending_amount = active_loan.amount

    case self.kind
    when 'demand'
      hold_margin_account.return_borrowed \
            lending_amount, active_loan.interest, reason: LendingAccount::LENDING_DONE, ref: active_loan
    when 'offer'
      hold_lending_account.plus_funds \
          lending_amount + active_loan.interest , fee: active_loan.fee, reason: LendingAccount::LENDING_DONE, ref: active_loan
    end

    true
  end

  def kind
    type.underscore[5..-1]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
  end

  def at
    created_at.to_i
  end

  def loan_market
    currency
  end

  def to_matching_attributes
    {
        id: id,
        loan_market: loan_market,
        type: type[4..-1].downcase.to_sym,
        rate: rate,
        amount: amount,
        duration: duration,
        auto_renew: auto_renew,
        timestamp: created_at.to_i
    }
  end

  def fix_number_precision
    self.rate = config.fix_number_precision(rate.to_d) if rate

    if amount
      self.amount = config.fix_number_precision(amount.to_d)
      self.origin_amount = origin_amount.present? ? config.fix_number_precision(origin_amount.to_d) : amount
    end
  end
end