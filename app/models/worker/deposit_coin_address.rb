module Worker
  class DepositCoinAddress
    def process(payload)
      payload.symbolize_keys!

      acc = Account.find_by_id(payload[:account_id])
      return unless acc

      acc.payment_address.tap do |pa|
        pa.with_lock do
          next if pa.address.present? || acc.currency_obj.erc20?

          options = acc.currency == 'xrp' ? { is_admin: acc.member.admin? } : {}
          result =  CoinAPI[acc.currency].new_address!(options)
          pa.update! result.extract!(:address, :secret, :tag).merge(details: result)
        end
      end

    end
  end
end
