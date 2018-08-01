class AddPaymentAddressIdToPaymentTransaction < ActiveRecord::Migration
  def change
    add_column :payment_transactions, :payment_address_id, :integer
  end
end
