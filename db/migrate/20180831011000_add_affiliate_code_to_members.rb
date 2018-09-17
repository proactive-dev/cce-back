class AddAffiliateCodeToMembers < ActiveRecord::Migration
  def change
    add_column :members, :affiliate_code, :string
  end
end
