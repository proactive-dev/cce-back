module Concerns
  module TriggerOrderCreation
    extend ActiveSupport::Concern

    def trigger_order_params(type)
      params[type][:bid] = params[:bid]
      params[type][:ask] = params[:ask]
      params[type][:state] = Order::WAIT
      params[type][:currency] = params[:market]
      params[type][:member_id] = current_user.id
      params[type][:volume] = params[type][:origin_volume]
      params[type][:source] = 'Web'
      params.require(type).permit(
        :bid, :ask, :currency, :price, :source, :rate,
        :state, :origin_volume, :volume, :member_id, :ord_type)
    end

    def submit_trigger_order
      begin
        TriggerOrdering.new(@trigger_order).submit
        render status: 200, json: success_result
      rescue
        Rails.logger.warn "Member id=#{current_user.id} failed to submit order: #{$!}"
        Rails.logger.warn params.inspect
        Rails.logger.warn $!.backtrace[0,20].join("\n")
        render_json(TriggerOrderCreateFail.new(@trigger_order.errors))
        #render status: 500, json: error_result(@trigger_order.errors)
      end
    end

    def success_result
      Jbuilder.encode do |json|
        json.result true
        json.message I18n.t("private.markets.show.success")
      end
    end

    def error_result(args)
      Jbuilder.encode do |json|
        json.result false
        json.message I18n.t("private.markets.show.error")
        json.errors args
      end
    end
  end
end
