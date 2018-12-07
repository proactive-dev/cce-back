class TriggerOrder < ActiveRecord::Base
  extend Enumerize

  enumerize :bid, in: Currency.enumerize
  enumerize :ask, in: Currency.enumerize
  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true

  # ORD_TYPES = %w(market limit)
  enumerize :ord_type, in: Order::ORD_TYPES, scope: true

  # SOURCES = %w(Web APIv2 debug)
  enumerize :source, in: Order::SOURCES, scope: true

  after_commit :trigger
  before_validation :fix_number_precision, on: :create

  validates_presence_of :ord_type, :volume, :origin_volume #, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false,
    if: "ord_type == 'limit'"
  # validate :market_order_validations, if: "ord_type == 'market'"

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  ATTRIBUTES = %w(id at market kind price state state_text volume origin_volume rate)

  belongs_to :member
  belongs_to :loan_demand
  has_many :orders

  attr_accessor :total

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  # scope :position, -> { group("price").pluck(:price, 'sum(volume)') }
  # scope :best_price, ->(currency) { where(ord_type: 'limit').active.with_currency(currency).matching_rule.position }

  # def funds_used
  #   origin_locked - locked
  # end

  def fee
    config[kind.to_sym]["fee"]
  end

  def config
    @config ||= Market.find(currency)
  end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end

    member.trigger('order', json)
  end

  def fill(amount)
    self.volume         -= amount
    self.funds_received += amount

    self.state = TriggerOrder::DONE if volume.zero?
    self.save!

    create_order(amount)
  end

  def kind
    type.underscore[-3, 3]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
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

  def to_matching_attributes
    { id: id,
      market: market,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      rate: rate,
      locked: locked,
      timestamp: created_at.to_i }
  end

  def fix_number_precision
    self.price = config.fix_number_precision(:bid, price.to_d) if price

    if volume
      self.volume = config.fix_number_precision(:ask, volume.to_d)
      self.origin_volume = origin_volume.present? ? config.fix_number_precision(:ask, origin_volume.to_d) : volume
    end
  end

  private

  # create order from trigger order
  def create_order(amount)
    order_params = {
      bid: bid,
      ask: ask,
      currency: currency,
      price: price,
      volume: amount,
      origin_volume: amount,
      member_id: member_id,
      ord_type: ord_type,
      state: Order::WAIT,
      source: 'Web',
      trigger_order_id: id
    }
    order = if kind == 'bid'
              OrderBid.new(order_params)
            else
              OrderAsk.new(order_params)
            end
    Ordering.new(order).submit

    self.orders_count += 1
    self.save!
  end

  # def market_order_validations
  #   errors.add(:price, 'must not be present') if price.present?
  # end

  # FUSE = '0.9'.to_d
  # def estimate_required_funds(price_levels)
  #   required_funds = Account::ZERO
  #   expected_volume = volume
  #
  #   start_from, _ = price_levels.first
  #   filled_at     = start_from
  #
  #   until expected_volume.zero? || price_levels.empty?
  #     level_price, level_volume = price_levels.shift
  #     filled_at = level_price
  #
  #     v = [expected_volume, level_volume].min
  #     required_funds += yield level_price, v
  #     expected_volume -= v
  #   end
  #
  #   raise "Market is not deep enough" unless expected_volume.zero?
  #   raise "Volume too large" if (filled_at-start_from).abs/start_from > FUSE
  #
  #   required_funds
  # end

end
