class TriggerOrdering

  class CancelOrderError < StandardError; end
  class InvalidOrderError < StandardError; end

  def initialize(order_or_orders)
    @trigger_orders = Array(order_or_orders)
  end

  def submit
    ActiveRecord::Base.transaction do
      @trigger_orders.each {|trigger_order| do_submit trigger_order }
    end
  end

  def cancel
    @trigger_orders.each {|trigger_order| do_cancel! trigger_order }
  end

  def cancel!
    ActiveRecord::Base.transaction do
      @trigger_orders.each do |trigger_order|
        do_cancel! trigger_order
      end
    end
  end

  private

  def do_submit(trigger_order)
    duration = 2 # default value
    if trigger_order.type.include? "Ask"
      amount = trigger_order.volume
      currency = trigger_order.ask
    else # TriggerBid
      amount = trigger_order.price * trigger_order.volume
      currency = trigger_order.bid
    end

    loan_demand = LoanDemand.create!(member_id: trigger_order.member_id, currency: currency,
                                     amount: amount, origin_amount: amount, duration: duration,
                                     rate: trigger_order.rate, state: OpenLoan::WAIT, source: 'Web')
    Loaning.new(loan_demand).submit

    trigger_order.loan_demand_id = loan_demand.id

    trigger_order.save!
  end

  def do_cancel!(trigger_order)
    if trigger_order.loan_demand.present?
      ActiveRecord::Base.transaction do
        loaning = Loaning.new(trigger_order.loan_demand)

        if loaning.cancel
          trigger_order.state = TriggerOrder::CANCEL
          trigger_order.save!

          return true
        end
      end
    end

    false
  end

end
