module Private
  class WithdrawsController < BaseController

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def create
      @withdraw = Withdraw.new(withdraw_params)

      if two_factor_auth_verified?
        if @withdraw.save
          @withdraw.submit!
          render nothing: true
        else
          render text: @withdraw.errors.full_messages.join(', '), status: 403
        end
      else
        render text: I18n.t('private.withdraws.create.two_factors_error'), status: 403
      end
    end

    def destroy
      Withdraw.transaction do
        @withdraw = current_user.withdraws.find(params[:id]).lock!
        @withdraw.cancel
        @withdraw.save!
      end
      render nothing: true
    end

    private

    def withdraw_params
      params[:withdraw][:member_id] = current_user.id
      params.require(:withdraw).permit(:fund_source, :member_id, :currency, :sum)
    end

  end
end
