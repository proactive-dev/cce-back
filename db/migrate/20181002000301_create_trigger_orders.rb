class CreateTriggerOrders < ActiveRecord::Migration
  def change
    create_table :trigger_orders do |t|
      t.integer  "bid"
      t.integer  "ask"
      t.integer  "currency"
      t.decimal  "price", precision: 32, scale: 16
      t.decimal  "volume", precision: 32, scale: 16
      t.decimal  "origin_volume", precision: 32, scale: 16
      t.decimal  "rate", precision: 32, scale: 16
      t.integer  "state"
      t.string   "type", limit: 10
      t.integer  "member_id"
      t.string   "source", null: false
      t.string   "ord_type", limit: 10
      t.decimal  "funds_received", precision: 32, scale: 16, default: 0.0
      t.integer  "orders_count", default: 0
      t.timestamps
    end
    add_index :trigger_orders, [:currency, :state], using: :btree
    add_index :trigger_orders, [:member_id, :state]
    add_index :trigger_orders, :member_id, using: :btree
    add_index :trigger_orders, :state
  end
end
