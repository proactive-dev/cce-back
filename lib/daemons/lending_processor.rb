#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

running = true
Signal.trap(:TERM) { running = false }

while running
  ActiveLoan.all.with_state(:wait).each do |active_loan|
    delta_date = active_loan.created_at.to_i + active_loan.duration.days - Time.now.to_i
    if delta_date <= 0
      active_loan.close
    end
  end

  Kernel.sleep 90
end
