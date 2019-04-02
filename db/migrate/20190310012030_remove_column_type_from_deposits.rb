class RemoveColumnTypeFromDeposits < ActiveRecord::Migration
  def change
    remove_column :deposits, :type
  end
end
