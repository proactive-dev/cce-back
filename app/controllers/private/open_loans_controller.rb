module Private
  class OpenLoansController < BaseController
    include Concerns::LoanCreation

    def create
      @loan = if params[:type] == "offer"
                LoanOffer.new(loan_params(:open_loan))
              else
                LoanDemand.new(loan_params(:open_loan))
              end
      loan_submit
    end

    def update
      ActiveRecord::Base.transaction do
        loan = current_user.open_loans.find(params[:id])
        loaning = Loaning.new(loan)

        if loaning.update
          render status: 200, nothing: true
        else
          render_json(LoanUpdateFail.new)
          #render status: 500, nothing: true
        end
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        loan = current_user.open_loans.find(params[:id])
        loaning = Loaning.new(loan)

        if loaning.cancel
          render status: 200, nothing: true
        else
          render_json(LoanCancelFail.new(@trigger_order.errors))
          #render status: 500, nothing: true
        end
      end
    end

    def clear
      @loans = current_user.open_loans.with_currency(current_market).with_state(:wait)
      Loaning.new(@loans).cancel
      render status: 200, nothing: true
    end

  end
end
