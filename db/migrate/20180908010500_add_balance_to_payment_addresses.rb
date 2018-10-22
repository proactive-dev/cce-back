class AddBalanceToPaymentAddresses < ActiveRecord::Migration
  def change
    add_column :payment_addresses, :balance, :decimal, precision: 32, scale: 16, default: 0, null: false
  end
end
