class AssetTransaction < ActiveRecord::Base
  include Currencible

  validates_presence_of :tx_id

end
