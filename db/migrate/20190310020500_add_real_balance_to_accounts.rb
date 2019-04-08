class AddRealBalanceToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :real_balance, :decimal, precision: 32, scale: 16, default: 0, null: false
    remove_column :payment_addresses, :balance
  end
end
