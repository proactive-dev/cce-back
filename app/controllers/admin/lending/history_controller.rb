module Admin
  module Lending
    class HistoryController < ::Admin::BaseController
      skip_load_and_authorize_resource

      def show
        @rejected_loans = OpenLoan.all.with_state(:reject)
        @canceled_loans = OpenLoan.all.with_state(:cancel)
        @opened_loans = OpenLoan.all.with_state(:wait).where("amount=origin_amount")
        active_loans = ::ActiveLoan.all
        @matched_offers = []
        @matched_demands = []
        active_loans.each do |active_loan|
          state = active_loan.state == ::ActiveLoan::WAIT ? OpenLoan::MATCHED : OpenLoan::DONE
          offer = LoanOffer.new(member_id: active_loan.offer_member_id, currency: active_loan.currency,
                                amount: active_loan.amount, origin_amount: active_loan.amount,
                                auto_renew: active_loan.auto_renew, rate: active_loan.rate, duration: active_loan.duration,
                                created_at: active_loan.created_at, state: state)
          demand = LoanDemand.new(member_id: active_loan.demand_member_id, currency: active_loan.currency,
                                  amount: active_loan.amount, origin_amount: active_loan.amount,
                                  rate: active_loan.rate, duration: active_loan.duration,
                                  created_at: active_loan.created_at, state: state)
          @matched_offers << offer
          @matched_demands << demand
        end

        @loans = (@rejected_loans + @canceled_loans + @opened_loans + @matched_offers + @matched_demands).sort_by {|t| -t.created_at.to_i }
        @loans = Kaminari.paginate_array(@loans).page(params[:page]).per(20)
      end
    end
  end
end
