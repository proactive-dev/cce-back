module Worker
  class DepositCoinAddress
    def process(payload)
      payload.symbolize_keys!

      acc = Account.find_by_id(payload[:account_id])
      return unless acc

      result = nil
      acc.payment_address.tap do |pa|
        pa.with_lock do
          next if pa.address.present?

          result = if acc.currency_obj.erc20?
                     get_eth_address(acc.member_id)
                   else
                     options = acc.currency == 'xrp' ? { is_admin: acc.member.admin? } : {}
                     CoinAPI[acc.currency].new_address!(options)
                   end

          pa.update! \
            result.extract!(:address, :secret, :tag).merge(details: result)

        end
      end

      generate_erc20(acc.member_id, result) if acc.currency == 'eth' && !result.nil?
    end

    def get_eth_address(member_id)
      account = Account.find_by(member_id: member_id, currency: Currency.find_by_code('eth').id)
      return unless account

      { address: account.payment_address.address, secret: account.payment_address.secret }
    end

    def generate_erc20(member_id, result)
      Currency.all.each do |currency|
        next if currency.fiat?
        next unless currency.erc20?

        account = Account.find_by(member_id: member_id, currency: currency.id)
        next unless account

        account.payment_address.tap do |p_address|
          p_address.with_lock do
            p_address.update! \
              result.extract!(:address, :secret).merge(details: result)

          end
        end
      end
    end
  end
end
