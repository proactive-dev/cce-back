class CreatePrices < ActiveRecord::Migration
  def change
    create_table :prices do |t|
      t.string :market_id
      t.integer :price_type, null: false, default: 0
      t.decimal :price, :precision => 32, :scale => 16, null: false, default: 0
      t.timestamps
    end

    add_index :prices, [:market_id], unique: true
  end
end
