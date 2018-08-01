class RemoveAddressFromPaymentTransactions < ActiveRecord::Migration
  def change
    remove_column :payment_transactions, :address
  end
end
