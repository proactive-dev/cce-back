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
    # TODO: check margin and force liquidation
    # if current_margin <

  end

  # Rails.logger.debug "margin_state timestamp: #{Time.now.to_i}"
  # sleep 1
end
