class ProofsGrid

  include Datagrid

  scope do
    Proof.order('id desc')
  end

  filter(:id, :integer)
  filter(:created_at, :date, :range => true)
  filter(:updated_at, :date, :range => true)

  column(:id)
  column(:currency)
  column(:address)
  column(:balance)
  column(:created_at) do |model|
    model.created_at.to_date
  end
  column(:updated_at) do |model|
    model.updated_at.to_date
  end
  column :actions, html: true, header: '' do |proof|
    # link_to I18n.t('actions.edit'), edit_admin_proof_path(proof)
  end
end
