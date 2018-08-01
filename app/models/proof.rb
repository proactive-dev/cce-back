class Proof < ActiveRecord::Base
  include Currencible

  validates_presence_of :currency
  validates_numericality_of :balance, allow_nil: true, greater_than_or_equal_to: 0

  delegate :coin?, to: :currency_obj

  def self.current(code)
    proofs = with_currency(code)
    proofs.last
  end

  def self.balance(code)
    total = 0
    with_currency(code).each do |proof|
      total += proof.balance unless proof.balance.nil?
    end
    total
  end

  def self.proofs(code)
    with_currency(code)
  end

  def timestamp
    Time.at(root['timestamp']/1000) || updated_at
  end

  def address_url(address)
    currency_obj.address_url(address)
  end
end
