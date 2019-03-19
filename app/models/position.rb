class Position < ActiveRecord::Base
  extend Enumerize

  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {open: 100, close: 200}, scope: true

  DIRECTIONS = %w(short long)
  enumerize :direction, in: DIRECTIONS, scope: true

  validates_presence_of :direction
  validates :member_id, uniqueness: { scope: :currency }

  OPEN = 'open'
  CLOSE = 'close'

  ATTRIBUTES = %w(id market member_id direction base_price amount volume lending_fees unrealized_lending_fee at state)

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

  def base_price
    self.amount == 0 ? 0 : (self.volume / self.amount).abs
  end

  def active_loans
    member.active_loans.select { |active_loan| active_loan.market == currency && active_loan.state == ActiveLoan::WAIT}
  end

  def unrealized_lending_fee
    total_base = 0
    total_quote = 0
    active_loans.each do |active_loan|
      if active_loan.currency == market_obj.quote_unit
        total_quote += active_loan.interest
      else
        total_base += active_loan.interest
      end
    end
    current_price * total_base + total_quote
  end

  def current_price
    ticker = Global[market_obj.id].ticker
    direction == 'long' ? ticker[:buy] : ticker[:sell]
  end

  def unrealized_pnl
    current_price * amount.abs - volume.abs - lending_fees
  end

  def update_lending_fee(lending_fee)
    self.lending_fees += lending_fee
    self.save!
  end

  def update(trade, is_from_position)
    # initialize first when closed
    if state == Position::CLOSE || state.blank?
      self.amount = 0
      self.volume = 0
      self.lending_fees = 0
      self.state = Position::OPEN
    end

    # close active loans
    if is_from_position
      remain_amount = direction == 'short' ? trade.volume : trade.volume * trade.price
      active_loans.each do |active_loan|
        if remain_amount >= active_loan.amount
          active_loan.close
          remain_amount -= active_loan.amount
          self.update_lending_fee(active_loan.interest)
        else
          active_loan.fill_volume(remain_amount)
          remain_amount = 0
          break
        end

      end
    end

    # re-calculate attributes
    if trade.side == 'ask' # 'ask'
      self.amount -= trade.volume
      self.volume += trade.volume * trade.price * (1 - market_obj.ask['fee'])
    else # 'bid'
      self.amount += trade.volume * (1 - market_obj.bid['fee'])
      self.volume -= trade.volume * trade.price
    end
    self.direction = self.amount >= 0 ? 'long' : 'short'

    # close position and calculate settlement
    if self.active_loans.blank?
      self.state = Position::CLOSE

      # TODO: calculate settlement
    end
    self.save!
  end

  def complete_close
    close(self.amount)
  end

  # request for closing position
  def close(amount)

    # place market order
    bid = market_obj.quote_unit
    ask = market_obj.base_unit
    fee = direction == 'short' ? market_obj.bid['fee'] : market_obj.ask['fee']
    vol =  amount / (1 - fee)
    order_params = {
        bid: bid,
        ask: ask,
        currency: currency,
        volume: vol,
        origin_volume: vol,
        member_id: member_id,
        ord_type: 'market',
        state: Order::WAIT,
        source: 'Position'
    }
    order = if direction == 'short'
              OrderBid.new(order_params)
            else
              OrderAsk.new(order_params)
            end
    Ordering.new(order).submit
  end

  def as_json(options = {})
    {
      id: id,
      direction: direction,
      amount: amount,
      market: market,
      member_id: member_id,
      base_price: base_price,
      volume: volume,
      lending_fees: lending_fees,
      unrealized_pnl: unrealized_pnl,
      unrealized_lending_fee: -unrealized_lending_fee,
      state: state
    }
  end

  private

end
