class PartialTree < ActiveRecord::Base

  belongs_to :account

  serialize :json, JSON
  validates_presence_of :account_id, :json

end
