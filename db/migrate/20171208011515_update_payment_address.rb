class UpdatePaymentAddress < ActiveRecord::Migration
  def change
    add_column :payment_addresses, :secret, :string, limit: 255
    add_column :payment_addresses, :details, :string, limit: 255, default: "{}"
  end
end
