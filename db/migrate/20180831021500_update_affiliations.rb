class UpdateAffiliations < ActiveRecord::Migration
  def change
    add_column :affiliations, :state, :integer
    add_column :affiliations, :amount, :decimal, precision: 32, scale: 16, default: 0
  end
end
