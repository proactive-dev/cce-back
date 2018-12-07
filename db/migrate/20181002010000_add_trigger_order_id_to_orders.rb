class AddTriggerOrderIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :trigger_order_id, :integer

    remove_column :trigger_orders, :locked
    remove_column :trigger_orders, :origin_locked
  end
end
