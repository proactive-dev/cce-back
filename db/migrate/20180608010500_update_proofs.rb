class UpdateProofs < ActiveRecord::Migration
  def change
    remove_column :partial_trees, :proof_id

    remove_column :proofs, :root
    remove_column :proofs, :ready
    remove_column :proofs, :sum
    remove_column :proofs, :addresses

    change_column :proofs, :balance, :decimal, precision: 32, scale: 16, default: 0, null: false

    add_column :proofs, :address, :string
    add_column :proofs, :secret, :string, limit: 255
    add_column :proofs, :details, :string, limit: 255, default: "{}"
  end
end
