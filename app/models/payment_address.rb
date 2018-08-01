class PaymentAddress < ActiveRecord::Base
  include Currencible
  belongs_to :account

  after_commit :gen_address

  has_many :transactions, class_name: 'PaymentTransaction'

  def gen_address
    AMQPQueue.enqueue(:deposit_coin_address, { account_id: account.id }, { persistent: true })
  end

  def memo
    address && address.split('|', 2).last
  end

  def deposit_address
    currency_obj[:deposit_account] || address
  end

  def as_json(options = {})
    {
      account_id: account_id,
      deposit_address: deposit_address
    }.merge(options)
  end

  def trigger_deposit_address
    ::Pusher["private-#{account.member.sn}"].trigger_async('deposit_address', { type: 'create', attributes: as_json })
  end

  def self.get_with(currency, entry)
    case currency.code
      when 'xrp'
        PaymentAddress.find_by(currency: currency.id, address: entry[:address], tag: entry[:tag])
      else
        PaymentAddress.find_by(currency: currency.id, address: entry[:address])
    end
  end

  def self.construct_memo(obj)
    member = obj.is_a?(Account) ? obj.member : obj
    checksum = member.created_at.to_i.to_s[-3..-1]
    "#{member.id}#{checksum}"
  end

  def self.destruct_memo(memo)
    member_id = memo[0...-3]
    checksum  = memo[-3..-1]

    member = Member.find_by_id member_id
    return nil unless member
    return nil unless member.created_at.to_i.to_s[-3..-1] == checksum
    member
  end

  def to_json
    { address: deposit_address }
  end
end
