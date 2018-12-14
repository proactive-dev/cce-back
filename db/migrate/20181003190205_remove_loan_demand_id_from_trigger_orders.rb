class RemoveLoanDemandIdFromTriggerOrders < ActiveRecord::Migration
  def change
    remove_column :trigger_orders, :loan_demand_id
    add_column :open_loans, :trigger_order_id, :integer
  end
end
