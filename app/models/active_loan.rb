class ActiveLoan < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions
  ZERO = '0.0'.to_d

  extend Enumerize
  enumerize :currency, in: LoanMarket.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true

  belongs_to :loan_market, class_name: 'LoanMarket', foreign_key: 'currency'
  belongs_to :demand, class_name: 'LoanDemand', foreign_key: 'demand_id'
  belongs_to :offer, class_name: 'LoanOffer', foreign_key: 'offer_id'

  belongs_to :demand_member, class_name: 'Member', foreign_key: 'demand_member_id'
  belongs_to :offer_member, class_name: 'Member', foreign_key: 'offer_member_id'
  belongs_to :order

  validates_presence_of :rate, :amount

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }

  scope :h24, -> { where("created_at > ?", 24.hours.ago) }

  attr_accessor :side

  class << self
    def latest_rate(currency)
      with_currency(currency).order(:id).reverse_order
          .limit(1).first.try(:rate) || "0.0".to_d
    end

    def filter(timestamp, from, to, limit, order)
      active_loans = ActiveLoan.all.order(order)
      active_loans = active_loans.with_state(:wait)
      active_loans = active_loans.limit(limit) if limit.present?
      active_loans = active_loans.where('created_at <= ?', timestamp) if timestamp.present?
      active_loans = active_loans.where('id > ?', from) if from.present?
      active_loans = active_loans.where('id < ?', to) if to.present?
      active_loans
    end

    def for_member(member, options={})
      active_loans = filter(options[:time_to], options[:from], options[:to], options[:limit], options[:order]).where("demand_member_id = ? or offer_member_id = ?", member.id, member.id)
      active_loans.each do |active_loan|
        active_loan.side = active_loan.type_of(member.id)
      end
    end
  end

  def trigger_offer
    offer.member.notify 'active_loan', for_notify('offer')
  end

  def trigger_notify
    demand.member.notify 'active_loan', for_notify('demand')
    offer.member.notify 'active_loan', for_notify('offer')
  end

  def type_of(member_id)
    demand_member_id == member_id ? 'demand' : 'offer'
  end

  def loan_auto_renew(kind)
    case kind || side
    when 'offer'
      auto_renew
    else
      nil
    end
  end

  def market
    demand.trigger_order.currency
  end

  def position
    member.positions.find_by(currency: market.id)
  end

  def interest
    loan_period = (Time.now.to_i - created_at.to_i) / 86400
    amount * loan_period * rate * 0.01
  end

  def fee(kind)
    case kind || side
    when 'demand'
      ZERO
    when 'offer'
      loan_market.fee * interest
    else
      nil
    end
  end

  def fill_volume(amount)
    self.volume -= amount
    self.save!
  end

  def close
    # close active loan
    raise "Cannot close loan. id: #{id}, state: #{state}" unless state == ActiveLoan::WAIT

    ActiveRecord::Base.transaction do
      if demand.unstrike(self)
        offer.unstrike(self)

        self.state = ActiveLoan::DONE
        self.save!
      end
    end
    trigger_notify

    renew_offer
  end

  def expire
    # expire active loan
    self.close

    renew_demand
  end

  def renew_offer
    return unless auto_renew

    ActiveRecord::Base.transaction do
      open_loan = LoanOffer.create!(member_id: offer_member_id, currency: currency,
                                     amount: amount, origin_amount: amount,
                                     auto_renew: auto_renew, rate: rate, duration: duration,
                                     state: OpenLoan::WAIT, source: 'Web')
      Loaning.new(open_loan).submit
    end
  end

  def renew_demand
    ActiveRecord::Base.transaction do
      open_loan = LoanDemand.create!(member_id: demand_member_id, currency: currency,
                                     amount: amount, origin_amount: amount,
                                     rate: ENV['LOAN_MAX_RATE'], duration: duration,
                                     state: OpenLoan::WAIT, source: 'Web', trigger_order: trigger_order, order_id: order_id)
      Loaning.new(open_loan).submit
    end
  end

  def for_notify(kind = nil)
    {
        id:     id,
        loan_market: loan_market.id,
        kind:   kind || side,
        rate:  rate.to_s  || ZERO,
        amount: amount.to_s || ZERO,
        duration: duration,
        at:     created_at.to_i,
        auto_renew: loan_auto_renew(kind),
        fee: fee(kind),
        state: state
    }
  end

end
