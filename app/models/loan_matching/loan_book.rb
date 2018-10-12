require_relative 'constants'

module LoanMatching
  class LoanBook

    attr :side

    def initialize(market, side, options={})
      @market = market
      @side   = side.to_sym
      @loans = RBTree.new

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
      @loans[loan.rate][loan.duration].find(loan.id)
    end

    def add(loan)
      raise InvalidLoanError, "amount is zero" if loan.amount <= ZERO

      @loans[loan.rate] ||= RBTree.new
      @loans[loan.rate][loan.duration] ||= LoanGroup.new
      @loans[loan.rate][loan.duration].add loan

      broadcast(action: 'add', loan: loan.attributes)
    end

    def remove(loan)
      remove_loan(loan)
    end

    def update(loan)
      update_loan(loan)
    end

    def loans
      loans = {}
      @loans.keys.each do |r|
        loans[r] = {}
        @loans[r].keys.each do |d|
          loans[r][d] = @loans[r][d].loans
        end
      end
      loans
    end

    def top(loan)
      return if @loans.nil? || @loans[loan.rate].nil? || @loans[loan.rate][loan.duration].nil?
      return if @loans.empty? || @loans[loan.rate].empty? || @loans[loan.rate][loan.duration].empty?

      @loans[loan.rate][loan.duration].top
    end

    private

    def remove_loan(loan)
      loan_group = @loans[loan.rate][loan.duration]
      return unless loan_group

      loan = loan_group.find loan.id # so we can return fresh loan
      return unless loan

      loan_group.remove loan
      @loans[loan.rate].delete(loan.duration) if loan_group.empty?
      @loans.delete(loan.rate) if @loans[loan.rate].empty?

      broadcast(action: 'remove', loan: loan.attributes)
      loan
    end

    def update_loan(loan)
      loan_group = @loans[loan.rate][loan.duration]
      return unless loan_group

      loan = loan_group.find loan.id # so we can return fresh loan
      return unless loan

      loan_group.update loan
      find(loan).auto_renew = !loan.auto_renew # only auto_renew would change

      loan
    end

    def broadcast(data)
      return unless @broadcast
      Rails.logger.debug "loanbook broadcast: #{data.inspect}"
      AMQPQueue.enqueue(:slave_loan_book, data, {persistent: false})
    end

  end
end
