module Private
  class TriggerOrdersController < BaseController

    def destroy
      ActiveRecord::Base.transaction do
        order = current_user.trigger_orders.find(params[:id])
        ordering = TriggerOrdering.new(order)

        if ordering.cancel
          render status: 200, nothing: true
        else
          render status: 500, nothing: true
        end
      end
    end

    def clear
      @orders = current_user.orders.with_currency(current_market).with_state(:wait)
      Ordering.new(@orders).cancel

      @orders = current_user.trigger_orders.with_currency(current_market).with_state(:wait)
      TriggerOrdering.new(@orders).cancel

      render status: 200, nothing: true
    end

  end
end
