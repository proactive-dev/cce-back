class PriceAPI
  class <<self

    def price(quote_currency, base_currency)
      if quote_currency == 'skb' || base_currency == 'usd'
        price_coinmarketcap(quote_currency, base_currency)
      elsif quote_currency == 'mas'
        0.0
      else
        price_binance(quote_currency + base_currency)
      end
    end

    def price_coinmarketcap(quote_currency, base_currency)
      price = 0
      conn = Faraday.new(url: 'https://api.coinmarketcap.com')
      response = conn.get "/v2/ticker/?convert=#{base_currency.upcase}"
      response_data = JSON.parse(response.body).fetch('data')
      response_data.each do |key, value|
        if value.fetch('symbol') == quote_currency.upcase
          price = value.fetch('quotes').fetch(base_currency.upcase).fetch('price')
        end
      end
      price
    end

    def price_binance(market)
      binance_api_client = Binance::Client::REST.new
      data = binance_api_client.price symbol: market.upcase
      data.fetch('price').to_f
    end
  end
end