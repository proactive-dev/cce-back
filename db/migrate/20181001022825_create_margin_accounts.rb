class CreateMarginAccounts < ActiveRecord::Migration
  def change
    create_table :margin_accounts do |t|
      t.integer :member_id
      t.integer :currency
      t.decimal :balance, :precision => 32, :scale => 16, default: 0
      t.decimal :locked, :precision => 32, :scale => 16, default: 0
      t.decimal :borrowed, :precision => 32, :scale => 16, default: 0
      t.decimal :borrow_locked, :precision => 32, :scale => 16, default: 0
      t.timestamps
    end

    add_index :margin_accounts, [:member_id, :currency]
    add_index :margin_accounts, :member_id
  end
end
