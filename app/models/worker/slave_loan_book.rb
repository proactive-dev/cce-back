module Worker
  class SlaveLoanBook

    def initialize(run_cache_thread=true)
      @managers = {}

      if run_cache_thread
        cache_thread = Thread.new do
          loop do
            sleep 3
            cache_book
          end
        end
      end
    end

    def process(payload, metadata, delivery_info)
      @payload = Hashie::Mash.new payload

      case @payload.action
      when 'new'
        @managers.delete(@payload.market)
        initialize_loan_book_manager(@payload.market)
      when 'add'
        book.add loan
      when 'update'
        book.find(loan).amount = loan.amount # only amount would change
      when 'remove'
        book.remove loan
      else
        raise ArgumentError, "Unknown action: #{@payload.action}"
      end
    rescue
      Rails.logger.error "Failed to process payload: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def cache_book
      @managers.keys.each do |id|
        market = LoanMarket.find id
        Rails.cache.write "exchange:#{market}:demands", get_data(market, :demand)
        Rails.cache.write "exchange:#{market}:offers", get_data(market, :offer)
      end
    rescue
      Rails.logger.error "Failed to cache loanbook: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def loan
      ::LoanMatching::LoanBookManager.build_loan @payload.loan.to_h
    end

    def book
      manager.get_books(@payload.loan.type.to_sym).first
    end

    def manager
      market = @payload.loan.loan_market
      @managers[market] || initialize_loan_book_manager(market)
    end

    def initialize_loan_book_manager(market)
      @managers[market] = ::LoanMatching::LoanBookManager.new(market, broadcast: false)
    end

    def get_data(market, side)
      data = []
      loans = @managers[market.id].send("#{side}_loans").loans
      if side == :offer
        data.push(*loans)
      else
        data.unshift(*loans)
      end

      data
    end

  end
end
