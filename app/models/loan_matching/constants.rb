module LoanMatching

  ZERO = 0.to_d unless defined?(ZERO)

  class DoubleSubmitError   < StandardError; end
  class InvalidLoanError   < StandardError; end
  class NotEnoughAmount     < StandardError; end
  class ExceedAmount      < StandardError; end
  class LendingExecutionError < StandardError; end

end
