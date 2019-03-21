module LoanMatching
  class LoanBookManager

    attr :demand_loans, :offer_loans

    def self.build_loan(attrs)
      attrs.symbolize_keys!

      ::LoanMatching::OpenLoan.new attrs
    end

    def initialize(market, options={})
      @market     = market
      @demand_loans = LoanBook.new(market, :demand, options)
      @offer_loans = LoanBook.new(market, :offer, options)
    end

    def get_books(type)
      case type
      when :demand
        [@demand_loans, @offer_loans]
      when :offer
        [@offer_loans, @demand_loans]
      end
    end

  end
end
