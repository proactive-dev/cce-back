class RemoveColumnBorrowedFromAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :borrowed
    remove_column :accounts, :borrow_locked
  end
end
