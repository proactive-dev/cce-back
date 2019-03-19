class CurrenciesController < ApplicationController

  layout false

  def index
    @currency_list = Currency.all.sort.map(&:as_json)
    render json: {currencies: @currency_list}.to_json, status: :ok
  end

end
