#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")


def process_depth(data)
  # first_updated = data.fetch('U')
  last_updated = data.fetch('u')
  market_id = data.fetch('s').downcase

  cached_last_update_id = Rails.cache.read "exchange:#{market_id}:last_update_id"
  last_update_id = if cached_last_update_id
                     cached_last_update_id
                   else
                     0
                   end


  if last_update_id <= last_updated
    AMQPQueue.enqueue :binance_processor, {event: 'depth_update', data: {market: market_id, bids: data.fetch('b'), asks: data.fetch('a')}}
  end
end

def process_ticker(data)
  market_id = data.fetch('s').downcase
  low = data.fetch('l').to_f
  high = data.fetch('h').to_f
  # open = data.fetch('o').to_f
  volume = data.fetch('q').to_f
  # timestamp = data.fetch('E')

  last = Rails.cache.read "exchange:#{market_id}:ticker:last"
  ticker = {
      low:  low   || ::Trade::ZERO,
      high: high  || ::Trade::ZERO,
      last: last || ::Trade::ZERO
  }
  Rails.cache.write "exchange:#{market_id}:ticker", ticker

  seconds  = Time.now.to_i
  time_key = seconds - (seconds % 5)
  Rails.cache.write "exchange:#{market_id}:h24_volume:#{time_key}", volume, expires_in: 24.hours

  Rails.cache.write "exchange:#{market_id}:h24:low", low, expires_in: 24.hours
  Rails.cache.write "exchange:#{market_id}:h24:high", high, expires_in: 24.hours
end


def process_trade(data)
  market_id = data.fetch('s').downcase
  price = data.fetch('p').to_f
  volume = data.fetch('q').to_f
  bid_id = data.fetch('b')
  ask_id = data.fetch('a')
  done_at = data.fetch('T')

  check_trade # TODO

  AMQPQueue.enqueue :binance_processor, {event: 'trade', data: {market: market_id, price: price, volume: volume}}
end

def check_trade

end

def process_message(message_data)
  data = JSON.parse(message_data)
  event = data.fetch('e')
  return unless event

  case event
    when 'trade'
      process_trade data
    when 'depthUpdate'
      process_depth data
    when '24hrMiniTicker'
      process_ticker data
  end
end

socket_client = Binance::Client::WebSocket.new

EM.run do

  # Create event handlers
  open    = proc { puts 'connected' }
  on_message = proc { |e| process_message e.data}
  on_error   = proc { |e| puts "error in socket: #{e}" }
  close   = proc { puts 'closed' }

  # Bundle our event handlers into Hash
  methods = { open: open, message: on_message, error: on_error, close: close }

  Market.from_binance.each do |market|
    socket_client.trade symbol: market.id.upcase, methods: methods
    socket_client.diff_depth symbol: market.id.upcase, methods: methods
    socket_client.single stream: { type: 'miniTicker', symbol: market.id.upcase}, methods: methods
  end
end
