class AddReferrerCodeToMembers < ActiveRecord::Migration
  def change
    add_column :members, :referrer_code, :string
  end
end
