require_relative 'constants'

module LoanMatching
  class OpenLoan
    attr :id, :timestamp, :type, :rate, :duration, :loan_market
    attr_accessor :amount, :auto_renew

    def initialize(attrs)
      @id         = attrs[:id]
      @timestamp  = attrs[:timestamp]
      @type       = attrs[:type].to_sym
      @amount     = attrs[:amount].to_d
      @rate      = attrs[:rate].to_d
      @duration  = attrs[:duration].to_i
      @auto_renew  = attrs[:auto_renew]
      @loan_market     = LoanMarket.find attrs[:loan_market]

      raise InvalidLoanError.new(attrs) unless valid?(attrs)
    end

    def lend_with(counter_loan)
      lending_amount = 0
      if @rate == counter_loan.rate && @duration == counter_loan.duration
        lending_amount = [@amount, counter_loan.amount.to_d].min
      end
      lending_amount
    end

    def fill(lending_amount)
      raise NotEnoughAmount if lending_amount > @amount
      @amount -= lending_amount
    end

    def filled?
      amount <= ZERO
    end

    def label
      "%d/$%s/%s" % [id, rate.to_s('F'), amount.to_s('F')]
    end

    def valid?(attrs)
      return false unless [:demand, :offer].include?(type)
      id && timestamp && loan_market && duration && rate > ZERO
    end

    def attributes
      { id: @id,
        timestamp: @timestamp,
        type: @type,
        amount: @amount,
        duration: @duration,
        rate: @rate,
        auto_renew: @auto_renew,
        loan_market: @loan_market.id }
    end

  end
end
