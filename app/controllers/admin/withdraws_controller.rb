module Admin
  class WithdrawsController < BaseController

    def index
      start_at = DateTime.now.ago(60 * 60 * 24 * 30)
      @withdraws = Withdraw.where(currency: params[:currency])
      @pending_withdraws = @withdraws.where(aasm_state: 'accepted').order("id DESC")
      @other_withdraws = @withdraws.where.not(aasm_state: 'accepted').where('created_at > ?', start_at).order("id DESC")
    end

    def show
      @withdraw = Withdraw.find_by(id: params[:id])
    end

    def update
      @withdraw = Withdraw.find_by(id: params[:id])
      @withdraw.process!
      redirect_to :back, notice: t('.notice')
    end

    def destroy
      @withdraw = Withdraw.find_by(id: params[:id])
      @withdraw.reject!
      redirect_to :back, notice: t('.notice')
    end
  end
end
