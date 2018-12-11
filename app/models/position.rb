class Position < ActiveRecord::Base
  extend Enumerize

  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {open: 100, close: 200}, scope: true

  DIRECTIONS = %w(short long)
  enumerize :direction, in: DIRECTIONS, scope: true

  after_commit :trigger

  validates_presence_of :direction

  OPEN = 'open'
  CLOSE = 'close'

  ATTRIBUTES = %w(id market member_id direction base_price amount at state)

  belongs_to :member

  scope :close, -> { with_state(:close) }
  scope :open, -> { with_state(:open) }

  def fee
    0
  end

  def at
    created_at.to_i
  end

  def market_obj
    Market.find currency
  end

  def market
    currency
  end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end
    member.trigger('position', json)
  end

  private

end
