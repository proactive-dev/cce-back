class CreateOpenLoans < ActiveRecord::Migration
  def change
    create_table :open_loans do |t|
      t.integer :currency
      t.integer :member_id
      t.decimal :rate, :precision => 32, :scale => 16
      t.decimal :amount, :precision => 32, :scale => 16
      t.decimal :origin_amount, :precision => 32, :scale => 16
      t.integer :duration
      t.boolean :auto_renew
      t.integer :state
      t.string :type
      t.datetime :done_at
      t.timestamps
      t.decimal :funds_received, :precision => 32, :scale => 16, default: 0
      t.integer :active_loans_count, default: 0
      t.string :source
    end
    add_index :open_loans, [:currency, :state], using: :btree
    add_index :open_loans, [:member_id, :state]
    add_index :open_loans, :member_id, using: :btree
    add_index :open_loans, :state
  end
end
