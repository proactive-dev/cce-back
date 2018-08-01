class AddFundTagToWithdraw < ActiveRecord::Migration
  def change
    add_column :withdraws, :fund_tag, :string
  end
end
