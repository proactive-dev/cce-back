class AddTagForXrp < ActiveRecord::Migration
  def change
    # Tag is used for destination_tag in XRP
    add_column :payment_addresses, :tag, :string, limit: 255

    add_column :fund_sources, :tag, :string, limit: 255

    add_column :proofs, :tag, :string, limit: 255
  end
end
