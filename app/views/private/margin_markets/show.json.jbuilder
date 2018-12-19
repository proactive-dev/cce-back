json.asks @asks
json.bids @bids
json.trades @trades

if @member
  json.my_trades @trades_done.map(&:for_notify)
  json.my_orders *([@orders_wait] + Order::ATTRIBUTES)
  json.my_margin_orders *([@margin_orders_wait] + TriggerOrder::ATTRIBUTES)
  json.my_position *([@position] + Position::ATTRIBUTES)
end
