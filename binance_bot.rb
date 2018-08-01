#
# Description:
#   This module (as known as "liquidity function") gets the ticker prices from Binance,
#   and opens the orders (buy/sell) to GoldenSTEC
# Author: 524
# Revision history:
#   Initial version: May 29th, 2018
#

require 'active_support'
require 'active_support/deprecation'
require 'net/http'
require 'json'
require 'peatio_client'
require 'binance'

BinanceApiKey = 'rBEdwLVMYUeA0ivg5WTsfYcWuEytFQTnbYc80p8yU9a6g5jU1qUtaW8oj6PfCtlK'
BinanceSecretKey = 'qAx2Hgx09qvn7AloxSDLV4q2IFbjfGv0hD2lBU5nk0U65fvuBp8QHzCJE9yixYoR'
GoldenstecAccessKey = 'PJj8Bx7MccYR1RIKX9kjEc2I5OkthLpobY2Sfidx' # AN5HJHAlkj8lkSx3cMXhV9xfim8v8ClOgWT1hMj5
GoldenstecSecretKey = 'MbF6mmxKVIDMVpTIwS4y0rk6ref6hSIvE5iRQSar' # gIcyQJdQN5zmAEMrF6xaxFNDIVXDMx5dOePo3EuQ
GoldenstecUrl = 'https://www.world-ct.com' # http://192.168.1.116:3000

@binance_client = Binance::Client::REST.new api_key: BinanceApiKey, secret_key: BinanceSecretKey
@peatio_client = PeatioAPI::Client.new access_key: GoldenstecAccessKey, secret_key: GoldenstecSecretKey, endpoint: GoldenstecUrl, timeout: 60

DebugMode = false # DebugMode is 'true' value at debug (development) mode, otherwise 'false'

def print_str(str)
  puts str if DebugMode
end

def print_obj(obj)
  p obj if DebugMode
end

while true
  # Note: the markets of 'DOGE/BTC' and 'VTC/BTC' weren't listed on Binance
  pairs = ['ltcbtc', 'xembtc', 'ethbtc', 'xrpbtc', 'bccbtc', 'dashbtc', 'sysbtc', 'etcbtc', 'dogebtc', 'vtcbtc']

  print_str '' # new line
  print_str '##### BEGIN'

  # Get the current order (24hr ticker price change statistics)
  binance_orders = @binance_client.twenty_four_hour

  binance_orders.each do |binance_order|
    pair = binance_order['symbol'].to_s.downcase

    next unless (pairs.include? pair)

    print_str '### Market-Symbol: ' + pair.to_s.upcase
    print_str '# Current order on Binance'
    print_str binance_order

    bid_price = binance_order['bidPrice']
    bid_volume = binance_order['bidQty'].to_f
    ask_price = binance_order['askPrice']
    ask_volume = binance_order['askQty'].to_f
    pair = 'bchbtc' if pair == 'bccbtc' # BCC/BTC on Binance but BCH/BTC on GoldenSTEC

    if bid_volume > 100 or bid_volume < 0.001
      bid_volume = Random.new.rand(0.001..99)
    end

    if ask_volume > 100 or ask_volume < 0.001
      ask_volume = Random.new.rand(0.001..99)
    end

    print_str '# With order of Binance, open "BUY" order on GoldenSTEC'
    print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: bid_volume, price: bid_price

    print_str '# With order of Binance, open "SELL" order on GoldenSTEC'
    print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: ask_volume, price: ask_price

    if bid_volume <= 2
      print_str '# Fully open "SELL" order on GoldenSTEC'
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: bid_volume, price: bid_price
    elsif bid_volume <= 20 and bid_volume > 2
      print_str '# Partially open "SELL" order: 1'
      partial_volume1 = Random.new.rand(0.001..bid_volume)
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: partial_volume1, price: bid_price

      sleep(1)

      print_str '# Partially open "SELL" order: 2'
      partial_volume2 = bid_volume - partial_volume1
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: partial_volume2, price: bid_price
    elsif bid_volume <= 100 and bid_volume > 20
      print_str '# Partially open "SELL" order: 1'
      partial_volume1 = Random.new.rand(0.001..bid_volume)
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: partial_volume1, price: bid_price

      sleep(1)

      print_str '# Partially open "SELL" order: 2'
      partial_volume2 = Random.new.rand(partial_volume1..bid_volume)
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: partial_volume2, price: bid_price

      sleep(1)

      print_str '# Partially open "SELL" order: 3'
      partial_volume3 = bid_volume - partial_volume2
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'sell', volume: partial_volume3, price: bid_price
    else
      print_str 'Can not be executed unfortunately'
    end

    sleep(1)

    if ask_volume <= 2
      print_str '# Fully open "BUY" order on GoldenSTEC'
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: ask_volume, price: ask_price
    elsif ask_volume <= 20 and ask_volume > 2
      print_str '# Partially open "BUY" order: 1'
      partial_volume1 = Random.new.rand(0.001..ask_volume)
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: partial_volume1, price: ask_price

      sleep(1)

      print_str '# Partially open "BUY" order: 2'
      partial_volume2 = ask_volume - partial_volume1
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: partial_volume2, price: ask_price
    elsif ask_volume <= 100 and ask_volume > 20
      print_str '# Partially open "BUY" order: 1'
      partial_volume1 = Random.new.rand(0.001..ask_volume)
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: partial_volume1, price: ask_price

      sleep(1)

      print_str '# Partially open "BUY" order: 2'
      partial_volume2 = Random.new.rand(partial_volume1..ask_volume)
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: partial_volume2, price: ask_price

      sleep(1)

      print_str '# Partially open "BUY" order: 3'
      partial_volume3 = ask_volume - partial_volume2
      print_obj @peatio_client.post '/api/v2/orders', market: pair, side: 'buy', volume: partial_volume3, price: ask_price
    else
      print_str 'Can not be executed unfortunately'
    end

    @peatio_client.post '/api/v2/orders/clear'

    sleep(2)
  end

  print_str '##### END'
end