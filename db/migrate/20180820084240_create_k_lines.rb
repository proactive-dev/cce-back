class CreateKLines < ActiveRecord::Migration
  def change
    create_table :k_lines do |t|
      t.integer :market
      t.datetime :start_at
      t.decimal :low,         precision: 32, scale: 16
      t.decimal :high,        precision: 32, scale: 16
      t.decimal :open,        precision: 32, scale: 16
      t.decimal :close,       precision: 32, scale: 16
      t.decimal :volume,      precision: 32, scale: 16
    end
  end
end
