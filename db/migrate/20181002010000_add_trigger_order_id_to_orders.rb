class AddTriggerOrderIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :trigger_order_id, :integer
  end
end
