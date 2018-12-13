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

def last_price(base_unit, quote_unit)
  if base_unit == quote_unit
    1
  else
    Global["#{base_unit}#{quote_unit}"].ticker[:last]
  end
end

while($running) do
  quote_unit = 'btc'

  Member.enabled.all.each do |member|
    total_margin = 0
    member.margin_accounts.non_zero.each do |margin_account|
      base_unit = margin_account.currency_obj.code
      total_margin += margin_account.balance * last_price(base_unit, quote_unit)
    end

    total_borrowed = 0
    unrealized_lending_fee = 0
    ActiveLoan.where(demand_member_id: member.id, state: ActiveLoan::WAIT).each do |active_loan|
      base_unit = active_loan.currency_obj.code
      price = last_price(base_unit, quote_unit)
      total_borrowed += active_loan.amount * price
      unrealized_lending_fee -= active_loan.interest * price
    end

    unrealized_pnl = 0 # TODO: calculate unrealized P/L

    net_value = total_margin + unrealized_lending_fee + unrealized_pnl
    current_margin = if total_borrowed > 0
                       net_value / total_borrowed * 100
                     else
                       100
                     end

    margin_info = {
        total_margin: total_margin,
        unrealized_pnl: unrealized_pnl,
        unrealized_lending_fee: unrealized_lending_fee,
        net_value: net_value,
        total_borrowed: total_borrowed,
        current_margin: current_margin,
        quote_unit: quote_unit
    }.to_json
    member.trigger('margin_info', margin_info)

    # TODO: check margin and force liquidation
    # if current_margin <

  end

  # Rails.logger.debug "margin_state timestamp: #{Time.now.to_i}"
  # sleep 1
end
