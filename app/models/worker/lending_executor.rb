module Worker
  class LendingExecutor

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!
      ::LoanMatching::Executor.new(payload).execute!
    rescue
      SystemMailer.lending_execute_error(payload, $!.message, $!.backtrace.join("\n")).deliver
      raise $!
    end

  end
end
