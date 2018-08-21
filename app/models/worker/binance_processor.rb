module Worker
  class BinanceProcessor

    FRESH_TRADES = 80

    def initialize
      @binance_api_client  = Binance::Client::REST.new

      init_market_data
      fetch_trades

      Thread.new do
        loop do
          fetch_depth

          30.times do |n|
            cache_depth
            sleep 2
          end
        end
      end
    end

    def process(payload, metadata, delivery_info)
      event = payload['event']
      data  = payload['data']

      case event
        when 'depth_update'
          market_id = data.fetch('market')
          bids = data.fetch('bids')
          asks = data.fetch('asks')

          update_depth(market_id, bids, asks)
        when 'trade'
          update_trades(data)
        else
          raise ArgumentError, "Unknown event: #{event}"
      end
    rescue
      Rails.logger.error "Failed to process payload: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    private

    def init_market_data
      @bid_depth = Hash.new
      @ask_depth = Hash.new

      @trades = {}

      Market.from_binance.each do |market|
        @bid_depth[market.id] = RBTree.new
        @ask_depth[market.id] = RBTree.new

        @trades[market.id] = Array.new
      end
    end

    def fetch_depth
      Market.from_binance.each do |market|
        data = @binance_api_client.depth symbol: market.id.upcase, limit: 200
        last_update_id = data.fetch('lastUpdateId')
        Rails.cache.write("exchange:#{market.id}:last_update_id", last_update_id, force: true)

        @bid_depth[market.id].clear
        @ask_depth[market.id].clear

        update_depth market.id, data.fetch('bids'), data.fetch('asks')
      end
    rescue
      Rails.logger.error "Failed to get depth: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def update_depth(market_id, bids, asks)
      bids.each do |order|
        @bid_depth[market_id][order[0]] = order[1]
        @bid_depth[market_id].delete_if{|k, v| v.to_f == 0}
      end

      asks.each do |order|
        @ask_depth[market_id][order[0]] = order[1]
        @ask_depth[market_id].delete_if{|k, v| v.to_f == 0}
      end
    end

    def cache_depth
      Market.from_binance.each do |market|

        bids = @bid_depth[market.id].to_a
        asks = @ask_depth[market.id].to_a
        bids.reverse!

        Rails.cache.write "exchange:#{market}:depth:asks", asks
        Rails.cache.write "exchange:#{market}:depth:bids", bids
      end
    rescue
      Rails.logger.error "Failed to cache depth: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def fetch_trades
      Market.from_binance.each do |market|
        data = @binance_api_client.trades symbol: market.id.upcase, limit: FRESH_TRADES
        data.each do |item|
          price = item.fetch('price').to_f
          volume = item.fetch('qty').to_f
          done_at = item.fetch('time')

          trade = Trade.new(price: price, volume: volume, funds: price*volume,
                                currency: market.id.to_sym)
          @trades[market.id].push trade
        end
        Rails.cache.write "exchange:#{market.id}:trades", @trades[market.id]
        Rails.cache.write "exchange:#{market.id}:ticker:last", @trades[market.id].last.try(:price) || ::Trade::ZERO
      end
    rescue
      Rails.logger.error "Failed to get trades: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def update_trades(data)
      market_id = data.fetch('market')
      price = data.fetch('price')
      volume = data.fetch('volume')

      trade = Trade.new(price: price, volume: volume, funds: price*volume,
                             currency: market_id.to_sym)
      trades = @trades[market_id]
      trades.unshift(trade.for_global)
      trades.pop if trades.size > FRESH_TRADES

      Rails.cache.write "exchange:#{market_id}:trades", trades
      Rails.cache.write "exchange:#{market_id}:ticker:last", price
    end

  end
end
