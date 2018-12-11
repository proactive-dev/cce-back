class Order < ActiveRecord::Base
  extend Enumerize

  enumerize :bid, in: Currency.enumerize
  enumerize :ask, in: Currency.enumerize
  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true

  ORD_TYPES = %w(market limit)
  enumerize :ord_type, in: ORD_TYPES, scope: true

  SOURCES = %w(Web APIv2 debug)
  enumerize :source, in: SOURCES, scope: true

  after_commit :trigger
  before_validation :fix_number_precision, on: :create

  validates_presence_of :ord_type, :volume, :origin_volume, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false,
    if: "ord_type == 'limit'"
  validate :market_order_validations, if: "ord_type == 'market'"

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  ATTRIBUTES = %w(id at market kind price state state_text volume origin_volume)

  belongs_to :member
  attr_accessor :total

  belongs_to :trigger_order

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :position, -> { group("price").pluck(:price, 'sum(volume)') }
  scope :best_price, ->(currency) { where(ord_type: 'limit').active.with_currency(currency).matching_rule.position }

  def funds_used
    origin_locked - locked
  end

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

  def strike(trade)
    raise "Cannot strike on cancelled or done order. id: #{id}, state: #{state}" unless state == Order::WAIT

    real_sub, add = get_account_changes trade
    real_fee      = add * fee
    real_add      = add - real_fee

    hold_account.unlock_and_sub_funds \
      real_sub, locked: real_sub,
      reason: Account::STRIKE_SUB, ref: trade

    expect_account.plus_funds \
      real_add, fee: real_fee,
      reason: Account::STRIKE_ADD, ref: trade

    self.volume         -= trade.volume
    self.locked         -= real_sub
    self.funds_received += add
    self.trades_count   += 1

    if volume.zero?
      self.state = Order::DONE

      # unlock not used funds
      hold_account.unlock_funds locked,
        reason: Account::ORDER_FULLFILLED, ref: trade unless locked.zero?
    elsif ord_type == 'market' && locked.zero?
      # partially filled market order has run out its locked fund
      self.state = Order::CANCEL
    end

    self.save!

    create_or_update_position(trade.volume) if trigger_order
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

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end

  FUSE = '0.9'.to_d
  def estimate_required_funds(price_levels)
    required_funds = Account::ZERO
    expected_volume = volume

    start_from, _ = price_levels.first
    filled_at     = start_from

    until expected_volume.zero? || price_levels.empty?
      level_price, level_volume = price_levels.shift
      filled_at = level_price

      v = [expected_volume, level_volume].min
      required_funds += yield level_price, v
      expected_volume -= v
    end

    raise "Market is not deep enough" unless expected_volume.zero?
    raise "Volume too large" if (filled_at-start_from).abs/start_from > FUSE

    required_funds
  end

  def create_or_update_position(trade_volume)
    position = Position.find_or_create_by(member_id: member_id, currency: currency)
    if position.state == Position::OPEN
      if kind == 'ask'
        position.amount -= trade.volume
      else # 'bid'
        position.amount += trade.volume
      end
    else # Position::CLOSE
      position.amount = trade_volume
      position.state = Position::OPEN
    end
    position.direction = position.amount >= 0 ? 'long' : 'short'
    # TODO: calculate base price

    position.save!
  end
end
