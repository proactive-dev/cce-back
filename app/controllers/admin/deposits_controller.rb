module Admin
  class DepositsController < BaseController
    def index
      start_at = DateTime.now.ago(60 * 60 * 24 * 365)
      @deposits = Deposit.where(currency: params[:currency])
                      .where('created_at > ?', start_at)
                      .order('id DESC').page(params[:page]).per(20)
    end

    def update
      @deposit = Deposit.find_by(id: params[:id])
      @deposit.accept! if @deposit.may_accept?
      redirect_to :back, notice: t('.notice')
    end
  end
end

