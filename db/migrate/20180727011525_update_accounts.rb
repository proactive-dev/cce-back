class UpdateAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :borrowed,:decimal, :precision => 32, :scale => 16, default: 0
    add_column :accounts, :borrow_locked,:decimal, :precision => 32, :scale => 16, default: 0
  end
end
