class PaymentAddress < ActiveRecord::Base
  include Currencible
  belongs_to :account

  after_commit :gen_address

  has_many :transactions, class_name: 'PaymentTransaction'

  def gen_address
    AMQPQueue.enqueue(:deposit_coin_address, { account_id: account.id }, { persistent: true })
  end

  def as_json(options = {})
    {
      deposit_address: address,
      tag: tag
    }.merge(options)
  end

  def self.get_with(currency, entry)
    if currency.erc20?
      PaymentAddress.find_by(currency: Currency.find_by_code('eth').id, address: entry[:address])
    elsif currency.neo_gas_or_nep5?
      PaymentAddress.find_by(currency: Currency.find_by_code('neo').id, address: entry[:address])
    else
      case currency.code
      when 'xrp'
        PaymentAddress.find_by(currency: currency.id, address: entry[:address], tag: entry[:tag])
      else
        PaymentAddress.find_by(currency: currency.id, address: entry[:address])
      end
    end
  end

  def to_json
    { address: address, tag: tag }
  end
end
