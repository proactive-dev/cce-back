class AddOrderIdToLoans < ActiveRecord::Migration
  def change
    add_column :open_loans, :order_id, :integer
    add_column :active_loans, :order_id, :integer
  end
end
