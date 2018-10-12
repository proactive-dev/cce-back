class CreateActiveLoans < ActiveRecord::Migration
  def change
    create_table :active_loans do |t|
      t.decimal :rate, :precision => 32, :scale => 16
      t.decimal :amount, :precision => 32, :scale => 16
      t.integer :duration
      t.integer :state
      t.integer :demand_id
      t.integer :offer_id
      t.integer  :currency
      t.timestamps
      t.integer :demand_member_id
      t.integer :offer_member_id
      t.boolean :demand_auto_renew
      t.boolean :offer_auto_renew
    end

    add_index :active_loans, :demand_id
    add_index :active_loans, :offer_id
    add_index :active_loans, :demand_member_id
    add_index :active_loans, :offer_member_id
    add_index :active_loans, :created_at, using: :btree
    add_index :active_loans, [:currency, :state], using: :btree
    add_index :active_loans, :state
  end
end
