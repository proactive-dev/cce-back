class Affiliation < ActiveRecord::Base
  extend Enumerize

  enumerize :state, in: {wait: 0, submitted: 100, done: 200, reject: 405, expire: 408}, scope: true

  validates_presence_of :affiliate, :referred
  validates_uniqueness_of :referred_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0

  WAIT = 'wait'
  SUBMITTED = 'submitted'
  DONE = 'done'
  REJECT = 'reject'
  EXPIRE = 'expire'

  belongs_to :affiliate, :class_name => "Member", :foreign_key => "affiliate_id"
  belongs_to :referred, :class_name => "Member", :foreign_key => "referred_id"

  scope :wait, -> { with_state(:wait) }
  scope :submitted, -> { with_state(:submitted) }

  def check
    self.amount = calculate_amount
    if self.amount <= 0
      self.state = Affiliation::EXPIRE
    else
      self.state = Affiliation::SUBMITTED
    end

    self.save!
  end

  private

  def calculate_amount
    amount = 0 # USD amount

    if referred.id_document and referred.id_document_verified?
      # calculate rule 1
      amount += 20

      # calculate rule 2
      deposits = referred.deposits.select {|deposit| deposit.currency == 2 && deposit.amount >= 0.1 }
      unless deposits.nil? || deposits.empty?
        total_btc_balance = 0
        referred.accounts.each do |account|
          total_btc_balance += PriceAPI.price(account.currency.code, 'btc') * (account.balance + account.locked)
        end
        amount += 50 if total_btc_balance >= 0.05
      end

      # calculate rule 3
      trade_amount = Hash.new {|h, k| h[k] = 0 }
      referred.trades.each do |trade|
        base_currency = trade.currency.bid_currency
        trade_amount[base_currency.code] +=  trade.funds
      end
      total_btc_trade = 0
      trade_amount.each do |key, value|
        if key == 'btc'
          total_btc_trade += value
        else
          total_btc_trade += PriceAPI.price(key, 'btc') * value
        end
      end
      amount += 100 if total_btc_balance >= 1
    end

    # calculate amount as BTC (USD to BTC)
    amount = amount / PriceAPI.price('btc', 'usd') if amount > 0
    amount
  end

  def validate
    raise "Affiliate and Referrer can't be the same user." if affiliate and (affiliate == referred)
  end

end