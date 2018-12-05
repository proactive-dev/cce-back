require_relative 'constants'

module LoanMatching
  class LoanBook

    attr :side

    def initialize(market, side, options={})
      @market = market
      @side   = side.to_sym
      @loans = []

      @broadcast = options.has_key?(:broadcast) ? options[:broadcast] : true
      broadcast(action: 'new', market: @market, side: @side)
    end

    def fill_top(counter_loan, lending_amount)
      loan = top(counter_loan)
      raise "No top loan in empty book." unless loan

      loan.fill lending_amount
      if loan.filled?
        remove loan
      else
        broadcast(action: 'update', loan: loan.attributes)
      end
    end

    def find(loan)
      @loans.find {|o| o.id == loan.id }
    end

    def add(loan)
      raise InvalidLoanError, "amount is zero" if loan.amount <= ZERO

      @loans << loan

      # Sort after adding a loan
      @loans = @loans.sort_by { |l| l.rate }
      @loans.reverse! if loan.type == :demand

      broadcast(action: 'add', loan: loan.attributes)
    end

    def remove(loan)
      remove_loan(loan)
    end

    def update(loan)
      update_loan(loan)
    end

    def loans
      @loans
    end

    def top(loan)
      return if @loans.blank?

      if loan.type == :demand
        loans = @loans.reject { |l| l.rate > loan.rate }
        loans = loans.sort_by { |l| l.rate }
      else # :offer
        loans = @loans.reject { |l| l.rate < loan.rate }
        loans = loans.sort_by { |l| l.rate }
        loans.reverse!
      end

      loans.first
    end

    private

    def remove_loan(loan)
      return if @loans.blank?

      @loans.delete_if {|o| o.id == loan.id }

      broadcast(action: 'remove', loan: loan.attributes)
      loan
    end

    def update_loan(loan)
      return if @loans.blank?

      exist_loan = find(loan) # so we can return fresh loan
      return unless exist_loan

      loan.auto_renew = !loan.auto_renew
      @loans.map { |l| l.id == loan.id ? loan : l }

      loan.auto_renew = !loan.auto_renew # only auto_renew would change

      loan
    end

    def broadcast(data)
      return unless @broadcast
      Rails.logger.debug "loanbook broadcast: #{data.inspect}"
      AMQPQueue.enqueue(:slave_loan_book, data, {persistent: false})
    end

  end
end
