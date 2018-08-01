module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def audit!
      result = CoinAPI[currency].validate_address!(fund_uid)

      if result.nil? || (result[:isvalid] == false)
        Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
        reject
        save!
      else
        super
      end
    end

    def as_json(options={})
      super(options).merge({
        blockchain_url: blockchain_url
      })
    end
  end
end

