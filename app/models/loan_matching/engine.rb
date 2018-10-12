module LoanMatching
  class Engine

    attr :loanbook, :mode, :queue
    delegate :demand_loans, :offer_loans, to: :loanbook

    def initialize(market, options={})
      @market    = market
      @loanbook = LoanBookManager.new(market.id)

      # Engine is able to run in different mode:
      # dryrun: do the match, do not publish the active_loans
      # run:    do the match, publish the active_loans (default)
      shift_gears(options[:mode] || :run)
    end

    def submit(open_loan)
      book, counter_book = loanbook.get_books open_loan.type
      match open_loan, counter_book
      add_or_cancel open_loan, book
    rescue
      Rails.logger.fatal "Failed to submit open_loan #{open_loan.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def cancel(open_loan)
      book, counter_book = loanbook.get_books open_loan.type
      if removed_loan = book.remove(open_loan)
        publish_cancel removed_loan, "cancelled by user"
      else
        Rails.logger.warn "Cannot find open_loan##{open_loan.id} to cancel, skip."
      end
    rescue
      Rails.logger.fatal "Failed to cancel open_loan #{open_loan.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def reject(open_loan)
      book, counter_book = loanbook.get_books open_loan.type
      if removed_loan = book.remove(open_loan)
        publish_reject removed_loan, "rejected by admin"
      else
        Rails.logger.warn "Cannot find open_loan##{open_loan.id} to reject, skip."
      end
    rescue
      Rails.logger.fatal "Failed to cancel open_loan #{open_loan.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def update(open_loan)
      book, counter_book = loanbook.get_books open_loan.type
      if updated_loan = book.update(open_loan)
        publish_update updated_loan, "updated by user"
      else
        Rails.logger.warn "Cannot find open_loan##{open_loan.id} to update, skip."
      end
    rescue
      Rails.logger.fatal "Failed to update open_loan #{open_loan.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def loans
      { demand: demand_loans.loans,
        offer: offer_loans.loans }
    end

    def shift_gears(mode)
      case mode
      when :dryrun
        @queue = []
        class <<@queue
          def enqueue(*args)
            push args
          end
        end
      when :run
        @queue = AMQPQueue
      else
        raise "Unrecognized mode: #{mode}"
      end

      @mode = mode
    end

    private

    def match(open_loan, counter_book)
      return if open_loan.filled?

      counter_loan = counter_book.top(open_loan)
      return unless counter_loan

      lending_amount = open_loan.lend_with(counter_loan)
      if lending_amount > 0
        counter_book.fill_top(counter_loan, lending_amount)
        open_loan.fill lending_amount

        publish open_loan, counter_loan, lending_amount

        match open_loan, counter_book
      end
    end

    def add_or_cancel(open_loan, book)
      return if open_loan.filled?
      open_loan.is_a?(OpenLoan) ?
        book.add(open_loan) : publish_cancel(open_loan, "fill or kill market open_loan")
    end

    def publish(open_loan, counter_loan, lending_amount)
      demand, offer = open_loan.type == :demand ? [open_loan, counter_loan] : [counter_loan, open_loan]

      rate  = @market.fix_number_precision open_loan.rate
      amount = @market.fix_number_precision lending_amount
      duration = open_loan.duration

      Rails.logger.info "[#{@market.id}] new active_loan - demand: #{demand.label} offer: #{offer.label} rate: #{rate} amount: #{amount}"

      @queue.enqueue(
        :lending_executor,
        {market_id: @market.id, demand_id: demand.id, offer_id: offer.id, strike_rate: rate, amount: amount, duration: duration},
        {persistent: false}
      )
    end

    def publish_cancel(open_loan, reason)
      publish_operation(open_loan, 'cancel',reason)
    end

    def publish_reject(open_loan, reason)
      publish_operation(open_loan, 'reject',reason)
    end

    def publish_update(open_loan, reason)
      publish_operation(open_loan, 'update',reason)
    end

    def publish_operation(open_loan, action, reason)
      Rails.logger.info "[#{@market.id}] #{action} open_loan ##{open_loan.id} - reason: #{reason}"
      @queue.enqueue(
        :loan_processor,
        {action: action, open_loan: open_loan.attributes},
        {persistent: false}
      )
    end

  end
end
