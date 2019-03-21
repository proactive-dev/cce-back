class Price < ActiveRecord::Base
  extend Enumerize

  PRICE_TYPE = {normal: 0, min_limit: 1, fixed: 2}

  validates :market_id, presence: true, uniqueness: true
  validates :price, numericality: {greater_than_or_equal_to: 0}

  enumerize :price_type, in: PRICE_TYPE, default: :normal

  class << self

    def update(market_id, type, value)
      unless value.nil? || value.empty?
        price = Price.find_by(market_id: market_id)
        price.price_type = type
        price.price = value.to_d
        price.save!
      end
    end

  end

  def market_name
    Market.find(market_id).name
  end
end
