module Private
  class LoanMarketsController < BaseController
    skip_before_action :auth_member!, only: [:show]
    before_action :visible_loan_market?, only: [:show]
    after_action :set_default_loan_market, only: [:show]

    layout false

    def show
      @offer = params[:offer]
      @demand = params[:demand]

      @loan_market      = current_loan_market
      @loan_markets     = LoanMarket.all.sort

      @offers   = @loan_market.offers
      @demands  = @loan_market.demands
      @active_loans = @loan_market.active_loans

      @loan = OpenLoan.new

      set_member_data if current_user
      gon.jbuilder
    end

    def update
      active_loan_id = params[:active_loan_id]
      kind = params[:kind]
      active_loan = ActiveLoan.find_by_id(active_loan_id)
      auto_renew = active_loan.send("#{kind}_auto_renew")

      ActiveRecord::Base.transaction do
        eval "active_loan.#{kind}_auto_renew = #{!auto_renew}"

        if active_loan.save!
          active_loan.trigger_active_loan(kind)

          render status: 200, nothing: true
        else
          render status: 500, nothing: true
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
      @loans_wait = @member.open_loans.with_state(:wait)
      @loans_active = ActiveLoan.for_member(current_user, limit: 100, loan: 'id desc')
    end

  end
end
