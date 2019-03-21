class AddTriggerOrderIdToOpenLoans < ActiveRecord::Migration
  def change
    add_column :open_loans, :trigger_order_id, :integer
  end
end
