require_relative 'constants'

module LoanMatching
  class Executor

    def initialize(payload)
      @payload = payload
      @market  = LoanMarket.find payload[:market_id]
      @rate   = BigDecimal.new payload[:strike_rate]
      @amount  = BigDecimal.new payload[:amount]
      @duration = payload[:duration]
    end

    def execute!
      retry_on_error(5) { create_active_loans }
      publish_lending
      @active_loan
    end

    private

    def valid?
      return false if @demand.rate < @rate
      return false if @offer.rate > @rate
      [@demand.amount, @offer.amount].min >= @amount
    end

    # in worst condition, the method will run 1+retry_count times then fail
    def retry_on_error(retry_count, &block)
      block.call
    rescue ActiveRecord::StatementInvalid
      # cope with "Mysql2::Error: Deadlock found ..." exception
      if retry_count > 0
        sleep 0.2
        retry_count -= 1
        puts "Retry active_loan execution (#{retry_count} retry left) .."
        retry
      else
        puts "Failed to execute active_loan: #{@payload.inspect}"
        raise $!
      end
    end

    def create_active_loans
      ActiveRecord::Base.transaction do
        @demand = LoanDemand.lock(true).find(@payload[:demand_id])
        @offer = LoanOffer.lock(true).find(@payload[:offer_id])

        raise LendingExecutionError.new({demand: @demand, offer: @offer, rate: @rate, amount: @amount}) unless valid?

        @active_loan = ActiveLoan.create!(demand_id: @demand.id, demand_member_id: @demand.member_id, order_id: @demand.order_id,
                               offer_id: @offer.id, offer_member_id: @offer.member_id, auto_renew: @offer.auto_renew,
                               rate: @rate, amount: @amount, currency: @market.id.to_sym, duration: @duration, state: ActiveLoan::WAIT)

        @offer.strike @active_loan
        @demand.strike @active_loan
      end

      # TODO: temporary fix, can be removed after pusher -> polling refactoring
      if @active_loan.demand_member_id == @active_loan.offer_member_id
        @demand.hold_margin_account.reload.trigger
        @offer.hold_lending_account.reload.trigger
      end
    end

    def publish_lending
      AMQPQueue.publish(
        :lending,
        @active_loan.as_json,
        { headers: {
            market: @market.id,
            demand_member_id: @demand.member_id,
            offer_member_id: @offer.member_id
          }
        }
      )
    end

  end
end
