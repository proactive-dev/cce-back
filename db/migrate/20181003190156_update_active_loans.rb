class UpdateActiveLoans < ActiveRecord::Migration
  def change
    rename_column :active_loans, :offer_auto_renew, :auto_renew
    remove_column :active_loans, :demand_auto_renew
  end
end
