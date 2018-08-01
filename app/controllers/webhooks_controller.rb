class WebhooksController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action      :auth_anybody!
  before_action      :currency_exists!

  def tx_created
    # process coin deposit
    if params[:type] == 'transaction' && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], currency: params[:ccy])
      render :json => { :status => 'queued' }
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  private

  def currency_exists!
    # check validation of coin
    head :unprocessable_entity unless params[:ccy].in?(Currency.codes)
  end
end
