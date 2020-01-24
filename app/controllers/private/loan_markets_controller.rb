module Private
  class LoanMarketsController < BaseController
    skip_before_action :auth_member!, only: [:show]
    before_action :visible_loan_market?, only: [:show]
    # after_action :set_default_loan_market, only: [:show]

    layout false

    def show
      @loan_market      = current_loan_market
      @offers   = @loan_market.offers
      @demands  = @loan_market.demands

      set_member_data if current_user
      # gon.jbuilder
     
      data ={offers: @offers, demands: @demands}
      if @member
        data[:my_active_loans] = @loans_active.map(&:for_notify)
        data[:my_open_loan_offers] = @loan_offers_wait.map(&:for_notify)
      end

      render json: data.to_json, status: :ok 
    end

    def update
      active_loan_id = params[:id]
      active_loan = ActiveLoan.find_by_id(active_loan_id)
      auto_renew = active_loan.auto_renew

      ActiveRecord::Base.transaction do
        active_loan.auto_renew = !auto_renew

        if active_loan.save!
          render status: 200, nothing: true
        else
          render_json(LoanUpdateFail.new)
          #render status: 500, nothing: true
        end
      end
    end

    private

    def visible_loan_market?
      redirect_to loan_market_path(LoanMarket.first) if not current_loan_market.visible?
    end

    def set_default_loan_market
      cookies[:loan_market_id] = @loan_market.id
    end

    def set_member_data
      @member = current_user
      @loan_offers_wait = @member.open_loans.with_state(:wait).where(type: 'LoanOffer')
      @loans_active = ActiveLoan.for_member(current_user, limit: 100, loan: 'id desc')
    end

  end
end
