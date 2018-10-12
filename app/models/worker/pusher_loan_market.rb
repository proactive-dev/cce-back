module Worker
  class PusherLoanMarket

    def process(payload, metadata, delivery_info)
      active_loan = ActiveLoan.new payload
      active_loan.trigger_notify
    end

  end
end
