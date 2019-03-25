class AddReferrerIdsToMembers < ActiveRecord::Migration
  def change
    add_column :members, :referrer_ids, :string, default: []
  end
end
