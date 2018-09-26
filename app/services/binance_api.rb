class BinanceAPI
  class <<self

    def client
      api_key = "LIrVAqK27BDrgZQ30MhKcH6f4RiJ5U2Q1krravy4aDT7lHqFwor7tgMh5UsgQ70U"
      secret_key = "NzXrJn4xa3JzfAnGy8JUCDXNe4lOsNFQxI9aTHA01fuliUfspuy2PnHgFFTvXRnE"

      Binance::Client::REST.new api_key: api_key, secret_key: secret_key
    end

    def create_order(order)
      side = order.type[-3, 3].downcase == 'ask' ? 'SELL' : 'BUY'
      response = client.create_order!(symbol: order.market.upcase, side: side, type: order.ord_type,
                          quantity: order.origin_volume, price: order.price, time_in_force: 'GTC')
      response.fetch('orderId')
    end

    def create_test_order(order)
      side = order.type[-3, 3].downcase == 'ask' ? 'SELL' : 'BUY'
      response = client.create_test_order(symbol: order.market.upcase, side: side, type: order.ord_type,
                                      quantity: order.origin_volume, price: order.price, time_in_force: 'GTC')
      response.fetch('orderId')
    end

    def cancel_order(order)
      response = client.cancel_order!(symbol: order.market.upcase, orderId: order.binance_id)
      response
    end

    def my_trades(market_id)
      client.my_trades(symbol: market_id)
    end
  end
end