module Private
  class TriggerBidsController < BaseController
    include Concerns::TriggerOrderCreation

    def create
      @trigger_order = TriggerBid.new(trigger_order_params(:trigger_bid))
      submit_trigger_order
    end

    def clear
      @orders = OrderBid.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      Ordering.new(@orders).cancel

      @orders = TriggerBid.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      TriggerOrdering.new(@orders).cancel

      render status: 200, nothing: true
    end

  end
end
