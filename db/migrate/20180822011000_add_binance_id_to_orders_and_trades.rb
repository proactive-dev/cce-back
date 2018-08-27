class AddBinanceIdToOrdersAndTrades < ActiveRecord::Migration
  def change
    add_column :orders, :binance_id, :integer
    add_column :trades, :binance_id, :integer
  end
end
