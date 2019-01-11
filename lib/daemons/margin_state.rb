#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do
  $running = false
end

while($running) do
  Member.enabled.all.each do |member|
    current_margin = member.sync_margin_info('btc')
    if current_margin < ENV['MARGIN_MAINTENANCE'].to_d
      member.force_liquidation
    end

  end

  sleep 5
end
