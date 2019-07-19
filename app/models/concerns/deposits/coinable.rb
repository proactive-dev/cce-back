module Deposits
  module Coinable
    extend ActiveSupport::Concern

    included do
      validates_presence_of :payment_transaction_id
      validates_uniqueness_of :payment_transaction_id
      belongs_to :payment_transaction
    end

    def min_confirm?(confirmations)
      update_confirmations(confirmations)
      confirmations >= currency_obj.min_confirm && confirmations < currency_obj.max_confirm
    end

    def max_confirm?(confirmations)
      update_confirmations(confirmations)
      confirmations >= currency_obj.max_confirm
    end

    def update_confirmations(confirmations)
      if !self.new_record? && self.confirmations.to_s != confirmations.to_s
        self.update_attribute(:confirmations, confirmations.to_s)
      end
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def as_json(options = {})
      super(options).merge({
                               txid: txid,
                               confirmations: payment_transaction.nil? ? 0 : payment_transaction.confirmations,
                               blockchain_url: blockchain_url
      })
    end
  end
end
