class RemoveColumnTypeFromWithdraws < ActiveRecord::Migration
  def change
    remove_column :withdraws, :type
  end
end
