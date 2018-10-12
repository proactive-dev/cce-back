module Worker
  class LoanMatching

    class DryrunError < StandardError
      attr :engine

      def initialize(engine)
        @engine = engine
      end
    end

    def initialize(options={})
      @options = options
      reload 'all'
    end

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      case payload[:action]
      when 'submit'
        submit build_loan(payload[:loan])
      when 'cancel'
        cancel build_loan(payload[:loan])
      when 'update'
        update build_loan(payload[:loan])
      when 'reject'
        reject build_loan(payload[:loan])
      when 'reload'
        reload payload[:market]
      else
        Rails.logger.fatal "Unknown action: #{payload[:action]}"
      end
    end

    def submit( loan)
      engines[loan.loan_market.id].submit(loan)
    end

    def cancel(loan)
      engines[loan.loan_market.id].cancel(loan)
    end

    def reject(loan)
      engines[loan.loan_market.id].reject(loan)
    end

    def update(loan)
      engines[loan.loan_market.id].update(loan)
    end

    def reload(market)
      if market == 'all'
        LoanMarket.all.each {|market| initialize_engine market }
        Rails.logger.info "All engines reloaded."
      else
        initialize_engine LoanMarket.find(market)
        Rails.logger.info "#{market} engine reloaded."
      end
    rescue DryrunError => e
      # stop started engines
      engines.each {|id, engine| engine.shift_gears(:dryrun) unless engine == e.engine }

      Rails.logger.fatal "#{market} engine failed to start. OpenLoan matched during dryrun:"
      e.engine.queue.each do |active_loan|
        Rails.logger.info active_loan[1].inspect
      end
    end

    def build_loan(attrs)
      ::LoanMatching::LoanBookManager.build_loan attrs
    end

    def initialize_engine(market)
      create_engine market
      load_loans   market
      start_engine  market
    end

    def create_engine(market)
      engines[market.id] = ::LoanMatching::Engine.new(market, @options)
    end

    def load_loans(market)
      ::OpenLoan.active.with_currency(market.id).order('id asc').each do |loan|
        submit build_loan(loan.to_matching_attributes)
      end
    end

    def start_engine(market)
      engine = engines[market.id]
      if engine.mode == :dryrun
        if engine.queue.empty?
          engine.shift_gears :run
        else
          accept = ENV['ACCEPT_MINUTES'] ? ENV['ACCEPT_MINUTES'].to_i : 30
          loan_ids = engine.queue
            .map {|args| [args[1][:demand_id], args[1][:offer_id]] }
            .flatten.uniq

          loans = OpenLoan.where('created_at < ?', accept.minutes.ago).where(id: loan_ids)
          if loans.exists?
            # there're very old loans matched, need human intervention
            raise DryrunError, engine
          else
            # only buffered loans matched, just publish active_loans and continue
            engine.queue.each {|args| AMQPQueue.enqueue(*args) }
            engine.shift_gears :run
          end
        end
      else
        Rails.logger.info "#{market.id} engine already started. mode=#{engine.mode}"
      end
    end

    def engines
      @engines ||= {}
    end
  end
end
