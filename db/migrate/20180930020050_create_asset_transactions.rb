class CreateAssetTransactions < ActiveRecord::Migration
  def change

    create_table :asset_transactions do |t|
      t.string :tx_id
      t.decimal :amount, precision: 32, scale: 16, default: 0, null: false
      t.integer :currency
      t.timestamps
    end
  end
end
