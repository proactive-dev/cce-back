class CreateReferrals < ActiveRecord::Migration
  def change
    create_table :referrals do |t|
      t.integer  "member_id", null: false
      t.integer  "currency", null: false
      t.decimal  "amount", precision: 32, scale: 16, null: false, default: 0.0
      t.decimal  "total", precision: 32, scale: 16, null: false, default: 0.0
      t.integer  "trade_id"
      t.integer  "state"
    end

    add_index :referrals, [:currency, :state], using: :btree
    add_index :referrals, [:member_id, :state]
    add_index :referrals, :member_id, using: :btree
    add_index :referrals, :state
  end
end
