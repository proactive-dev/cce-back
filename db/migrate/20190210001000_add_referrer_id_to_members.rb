class AddReferrerIdToMembers < ActiveRecord::Migration
  def change
    add_column :members, :referrer_id, :integer
  end
end
