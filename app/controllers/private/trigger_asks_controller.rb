module Private
  class TriggerAsksController < BaseController
    include Concerns::TriggerOrderCreation

    def create
      @trigger_order = TriggerAsk.new(trigger_order_params(:trigger_ask))
      submit_trigger_order
    end

    def clear
      @orders = OrderAsk.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      Ordering.new(@orders).cancel

      @orders = TriggerAsk.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      TriggerOrdering.new(@orders).cancel

      render status: 200, nothing: true
    end

  end
end
