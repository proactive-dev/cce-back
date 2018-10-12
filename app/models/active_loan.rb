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

  def trigger_active_loan(kind)
    loan = eval "#{kind}"
    loan.member.notify 'active_loan', for_notify(kind)
  end

  def trigger_notify
    demand.member.notify 'active_loan', for_notify('demand')
    offer.member.notify 'active_loan', for_notify('offer')
  end

  def type_of(member_id)
    demand_member_id == member_id ? 'demand' : 'offer'
  end

  def auto_renew(kind)
    case kind || side
      when 'demand'
        demand_auto_renew
      when 'offer'
        offer_auto_renew
      else
        nil
    end
  end

  def fee(kind)
    case kind || side
      when 'demand'
        ZERO
      when 'offer'
        loan_market.fee * amount * rate * 0.01
      else
        nil
    end
  end

  def complete
    raise "Cannot complete Lending. id: #{id}, state: #{state}" unless state == ActiveLoan::WAIT

    ActiveRecord::Base.transaction do
      if demand.unstrike(self)
        offer.unstrike(self)

        self.state = ActiveLoan::DONE
        self.save!

      end
    end

    if self.state == ActiveLoan::DONE
      ActiveRecord::Base.transaction do
        if demand_auto_renew && !demand_member.disabled?
          @open_loan = LoanDemand.create!(member_id: demand_member_id, currency: currency,
                                          amount: amount, origin_amount: amount,
                                          auto_renew: demand_auto_renew, rate: rate, duration: duration,
                                          state: OpenLoan::WAIT, source: 'Web')
          Loaning.new(@open_loan).submit
        end

        if offer_auto_renew && !offer_member.disabled?
          @open_loan = LoanOffer.create!(member_id: offer_member_id, currency: currency,
                                         amount: amount, origin_amount: amount,
                                         auto_renew: offer_auto_renew, rate: rate, duration: duration,
                                         state: OpenLoan::WAIT, source: 'Web')
          Loaning.new(@open_loan).submit
        end

      end

      trigger_notify
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
        auto_renew: auto_renew(kind),
        fee: fee(kind),
        state: state
    }
  end

end
