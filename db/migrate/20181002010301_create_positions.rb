class CreatePositions < ActiveRecord::Migration
  def change
    create_table :positions do |t|
      t.string   "direction", limit: 5, null: false
      t.decimal  "amount", precision: 32, scale: 16, null: false, default: 0.0
      t.decimal  "volume", precision: 32, scale: 16, null: false, default: 0.0
      t.decimal  "lending_fees", precision: 32, scale: 16, null: false, default: 0.0
      t.integer  "currency", null: false
      t.integer  "member_id", null: false
      t.integer  "state"
      t.timestamps
    end
    add_index :positions, [:currency, :state], using: :btree
    add_index :positions, [:member_id, :state]
    add_index :positions, :member_id, using: :btree
    add_index :positions, :state
  end
end
