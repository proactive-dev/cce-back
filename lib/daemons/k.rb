#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

Rails.logger = @logger = Logger.new STDOUT

@r ||= KlineDB.redis

$running = true
Signal.trap("TERM") do
  $running = false
end


def key(market, period = 1)
  "exchange:#{market}:k:#{period}"
end

def last_ts(market, period = 1)
  latest = @r.lindex key(market, period), -1
  latest && Time.at(JSON.parse(latest)[0])
end

def next_ts(market, period = 1)
  if ts = last_ts(market.id, period)
    ts += period.minutes
  else
    if market.is_binance?
      if first_k_line = KLine.where(market: market.code).first
        ts = KLine.where(market: market.code).first.start_at.to_i
        period == 10080 ? Time.at(ts).beginning_of_week : Time.at(ts -  ts % (period * 60))
      end
    else # if market.is_inner?
      if first_trade = Trade.with_currency(market.id).first
        ts = Trade.with_currency(market.id).first.created_at.to_i
        period == 10080 ? Time.at(ts).beginning_of_week : Time.at(ts -  ts % (period * 60))
      end
    end
  end
end

def _k1_set(market, start, period)
  ts = JSON.parse(@r.lindex(key(market, 1), 0)).first

  left = offset = (start.to_i - ts) / 60
  left = 0 if left < 0

  right = offset + period - 1

  right < 0 ? [] : @r.lrange(key(market, 1), left, right).map{|str| JSON.parse(str)}
end

def k1(market_id, start)
  market = Market.find market_id
  if market.is_binance?
    k_line = KLine.find_by(market: market.code, start_at: start)
    return nil if k_line.nil?

    [start.to_i, k_line.open.to_f, k_line.high.to_f, k_line.low.to_f, k_line.close.to_f, k_line.volume.to_f.round(4)]
  else # if market.is_inner?
    trades = Trade.with_currency(market_id).where('created_at >= ? AND created_at < ?', start, 1.minutes.since(start)).pluck(:price, :volume)
    return nil if trades.count == 0

    prices, volumes = trades.transpose
    [start.to_i, prices.first.to_f, prices.max.to_f, prices.min.to_f, prices.last.to_f, volumes.sum.to_f.round(4)]
  end
end

def kn(market, start, period = 5)
  arr = _k1_set(market, start, period)
  return nil if arr.empty?

  _, _, high, low, _, volumes = arr.transpose
  [start.to_i, arr.first[1], high.max, low.min, arr.last[4], volumes.sum.round(4)]
end

def get_point(market, period, ts)
  point = period == 1 ? k1(market, ts) : kn(market, ts, period)

  if point.nil?
    point = JSON.parse @r.lindex(key(market, period), -1)
    point = [ts.to_i, point[4], point[4], point[4], point[4], 0]
  end

  point
end

def append_point(market, period, ts)
  k = key(market, period)
  point = get_point(market, period, ts)

  @logger.info "append #{k}: #{point.to_json}"
  @r.rpush k, point.to_json

  if period == 1
    # 24*60 = 1440
    if point = @r.lindex(key(market, period), -1441)
      Rails.cache.write "exchange:#{market}:ticker:open", JSON.parse(point)[4]
    end
  end
end

def update_point(market, period, ts)
  k = key(market, period)
  point = get_point(market, period, ts)

  @logger.info "update #{k}: #{point.to_json}"
  @r.rpop k
  @r.rpush k, point.to_json
end

def fill(market, period = 1)
  ts = next_ts(market, period)

  # 30 seconds is a protect buffer to allow update_point to update the previous
  # period one last time, after the previous period passed. After the protect
  # buffer a new point of current period will be created, the previous point
  # is freezed.
  #
  # The protect buffer also allows MySQL slave have enough time to sync data.
  while (ts + 30.seconds) <= Time.now
    append_point(market.id, period, ts)
    ts = next_ts(market, period)
  end

  update_point(market.id, period, last_ts(market.id, period))
end

while($running) do
  Market.all.each do |market|
    ts = next_ts(market, 1)
    next unless ts

    [1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 10080].each do |period|
      fill(market, period)
    end
  end

  sleep 15
end
