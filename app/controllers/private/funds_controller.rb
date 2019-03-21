module Private
  class FundsController < BaseController
    layout false
    # layout 'funds'

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    # def index
    #   @deposit_channels = DepositChannel.all
    #   @withdraw_channels = WithdrawChannel.all
    #   @currencies = Currency.all.sort
    #   @deposits = current_user.deposits
    #   @accounts = current_user.accounts.enabled
    #   @withdraws = current_user.withdraws
    #   @fund_sources = current_user.fund_sources
    #
    #   gon.jbuilder
    # end

    def gen_address
      current_user.accounts.each do |account|
        next if account.currency_obj.nil?
        next unless account.currency_obj.coin?
        next unless account.payment_address.address.blank?
        account.payment_address.gen_address
      end
      render nothing: true
    end

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

