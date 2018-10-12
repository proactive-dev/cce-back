module Worker
  class LoanProcessor

    def initialize
      @cancel_queue = []
      @reject_queue = []
      @update_queue = []
      create_thread
    end

    def process(payload, metadata, delivery_info)
      open_loan = payload['open_loan']
      case payload['action']
      when 'cancel'
        unless check_and_process('cancel', open_loan)
          @cancel_queue << open_loan
        end
      when 'reject'
        unless check_and_process('reject', open_loan)
          @reject_queue << open_loan
        end
      when 'update'
        unless check_and_process('update', open_loan)
          @update_queue << open_loan
        end
      else
        raise ArgumentError, "Unrecogonized action: #{payload['action']}"
      end
    rescue
      SystemMailer.loan_processor_error(payload, $!.message, $!.backtrace.join("\n")).deliver
      raise $!
    end

    def check_and_process(action, attrs)
      retry_count = 5
      begin
        open_loan = OpenLoan.find attrs['id']
        if open_loan.amount == attrs['amount'].to_d # all active_loans has been processed
          case action
            when 'cancel'
              Loaning.new(open_loan).cancel!
            when 'reject'
              Loaning.new(open_loan).reject!
            when 'update'
              Loaning.new(open_loan).update!
          end
          puts "OpenLoan##{open_loan.id} #{action} success."
          true
        end
      rescue ActiveRecord::StatementInvalid
        # in case: Mysql2::Error: Lock wait timeout exceeded
        if retry_count > 0
          sleep 0.5
          retry_count -= 1
          puts $!
          puts "Retry open_loan.#{action}! (#{retry_count} retry left) .."
          retry
        else
          puts "Failed to #{action} open_loan##{open_loan.id}"
          raise $!
        end
      end
    rescue Loaning::CancelLoanError
      puts "Skipped: #{$!}"
      true
    end

    def process_cancel_jobs
      queue = @cancel_queue
      @cancel_queue = []

      queue.each do |attrs|
        unless check_and_process('cancel', attrs)
          @cancel_queue << attrs
        end
      end

      Rails.logger.debug "Cancel queue size: #{@cancel_queue.size}"
    rescue
      Rails.logger.debug "Failed to process cancel job: #{$!}"
      Rails.logger.debug $!.backtrace.join("\n")
    end

    def process_reject_jobs
      queue = @reject_queue
      @reject_queue = []

      queue.each do |attrs|
        unless check_and_process('reject', attrs)
          @reject_queue << attrs
        end
      end

      Rails.logger.debug "Cancel queue size: #{@reject_queue.size}"
    rescue
      Rails.logger.debug "Failed to process cancel job: #{$!}"
      Rails.logger.debug $!.backtrace.join("\n")
    end

    def process_update_jobs
      queue = @update_queue
      @update_queue = []

      queue.each do |attrs|
        unless check_and_process('update', attrs)
          @update_queue << attrs
        end
      end

      Rails.logger.debug "Update queue size: #{@update_queue.size}"
    rescue
      Rails.logger.debug "Failed to process update job: #{$!}"
      Rails.logger.debug $!.backtrace.join("\n")
    end

    def create_thread
      Thread.new do
        loop do
          sleep 5
          process_cancel_jobs
          process_update_jobs
          process_reject_jobs
        end
      end
    end

  end
end
