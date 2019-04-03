module Private
  class FundsController < BaseController
    layout false
    # layout 'funds'

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def withdraws
      if params[:currency]
        render json: current_user.withdraws.where(currency: params[:currency])
      else  
        render json: current_user.withdraws
      end
    end

    def deposits
      if params[:currency]
        render json: current_user.deposits.where(currency: params[:currency])
      else
        render json: current_user.deposits
      end
    end
  end
end

