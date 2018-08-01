# TODO: Replace txout with composite TXID.
module Worker
  class DepositCoin

    def process(payload)
      payload.symbolize_keys!

      ccy = Currency.find_by_code!(payload.fetch(:currency))
      tx  = ccy.api.load_deposit(payload.fetch(:txid))

      if tx
        ActiveRecord::Base.transaction do
          tx.fetch(:entries).each_with_index { |entry, index| deposit!(ccy, tx, entry, index) }
        end
      else
        Rails.logger.info "Could not load #{ccy.code.upcase} deposit #{payload.fetch(:txid)}."
      end
    end

  private

    def deposit!(currency, tx, entry, index)
      address = PaymentAddress.get_with(currency, entry)

      return Rails.logger.info "Skipped #{tx.fetch(:id)}:#{index}." if address.nil? || PaymentTransaction::Normal.where(txid: tx[:id], txout: index).exists?

      pt = PaymentTransaction::Normal.create! \
        txid:          tx[:id],
        txout:         index,
        amount:        entry[:amount],
        confirmations: tx[:confirmations],
        receive_at:    tx[:received_at],
        currency:      currency.code,
        payment_address: address

      pt.make_deposit

      Rails.logger.debug "Successfully processed #{tx.fetch(:id)}:#{index}."
    rescue StandardError => e
      Rails.logger.error { "Failed to process #{tx.fetch(:id)}:#{index}." }
      Rails.logger.fatal { e.inspect }
    end
  end
end
