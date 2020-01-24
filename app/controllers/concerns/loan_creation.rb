module Concerns
  module LoanCreation
    extend ActiveSupport::Concern

    def loan_params(open_loan)
      params[open_loan][:state] = OpenLoan::WAIT
      params[open_loan][:currency] = params[:loan_market_id]
      params[open_loan][:member_id] = current_user.id
      params[open_loan][:amount] = params[open_loan][:origin_amount]
      params[open_loan][:source] = 'Web'
      params.require(open_loan).permit(
        :currency, :rate, :amount, :origin_amount, :duration, :auto_renew,
        :member_id, :source, :state)
    end

    def loan_submit
      begin
        Loaning.new(@loan).submit
        render status: 200, json: success_result
      rescue
        Rails.logger.warn "Member id=#{current_user.id} failed to submit loan: #{$!}"
        Rails.logger.warn params.inspect
        Rails.logger.warn $!.backtrace[0,20].join("\n")
        render_json(LoanCreateFail.new(@loan.errors))
        #render status: 500, json: error_result(@loan.errors)
      end
    end

    def success_result
      Jbuilder.encode do |json|
        json.result true
        json.message I18n.t("private.loan_markets.show.success")
      end
    end

    def error_result(args)
      Jbuilder.encode do |json|
        json.result false
        json.message I18n.t("private.loan_markets.show.error")
        json.errors args
      end
    end
  end
end
