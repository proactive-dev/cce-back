# People exchange commodities in loan_markets. Each loan_market focuses on certain
# commodity pair `{A, B}`. By convention, we call people exchange A for B
# *sellers* who submit *ask* orders, and people exchange B for A *buyers*
# who submit *bid* orders.
#
# ID of loan_market is always in the form "#{B}#{A}". For example, in 'btccny'
# loan_market, the commodity pair is `{btc, cny}`. Sellers sell out _btc_ for
# _cny_, buyers buy in _btc_ with _cny_. _btc_ is the `base_unit`, while
# _cny_ is the `quote_unit`.

class LoanMarket < ActiveYamlBase
  field :visible, default: true

  attr :name

  self.singleton_class.send :alias_method, :all_with_invisible, :all

  def self.all
    all_with_invisible.select &:visible
  end

  def self.enumerize
    all_with_invisible.inject({}) {|hash, i| hash[i.id.to_sym] = i.code; hash }
  end

  def self.to_hash
    return @loan_markets_hash if @loan_markets_hash

    @loan_markets_hash = {}
    all.each {|m| @loan_markets_hash[m.id.to_sym] = m.unit_info }
    @loan_markets_hash
  end

  def initialize(*args)
    super

    @name = self[:name]
  end

  def latest_rate
    ActiveLoan.latest_rate(id.to_sym)
  end

  def fix_number_precision(d)
    d.round precision, 2
  end

  # shortcut of global access
  def offers; global.offers end
  def demands; global.demands end
  def active_loans; global.active_loans end

  def to_s
    id
  end

  def currency
    Currency.find_by_code(id)
  end

  def scope?(account_or_currency)
    code = if account_or_currency.is_a? LendingAccount
             account_or_currency.currency
           elsif account_or_currency.is_a? Currency
             account_or_currency.code
           else
             account_or_currency
           end

    id == code
  end

  def unit_info
    {name: name, id: id}
  end

  private

  def global
    @global || Global[self.id]
  end

end
