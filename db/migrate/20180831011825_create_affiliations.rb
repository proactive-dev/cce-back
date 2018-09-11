class CreateAffiliations < ActiveRecord::Migration
  def change
    create_table :affiliations do |t|
      t.integer :affiliate_id
      t.integer :referred_id
      t.timestamps
    end
  end
end
