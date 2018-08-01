module Worker
  class WithdrawCoin
    def process(payload)
      payload.symbolize_keys!

      withdraw = Withdraw.lock.find_by_id(payload[:id])
      return if withdraw.blank? || !withdraw.processing?

      withdraw.transaction do

        if true # withdraw from exchange accounts
          pa = Proof.current(withdraw.currency)

          withdraw.mark_suspect if pa.nil? || pa.address.blank?

          balance = CoinAPI[withdraw.currency].load_balance_of!(pa.address)

          withdraw.mark_suspect if balance < withdraw.sum
        else
          balance = CoinAPI[withdraw.currency].load_balance!

          withdraw.mark_suspect if balance < withdraw.sum

          pa = withdraw.account.payment_address
        end

        if withdraw.suspect?
          Rails.logger.info { "#{withdraw.currency} withdraw with ID #{withdraw.id}: suspect." }
          withdraw.save!
        else
          recipient = { address: withdraw.fund_uid }
          recipient[:tag]= withdraw.fund_tag unless withdraw.fund_tag.nil?

          txid = CoinAPI[withdraw.currency].create_withdrawal!(
              { address: pa.address, secret: pa.secret, tag: pa.tag },
              recipient,
              withdraw.amount.to_d
          )

          withdraw.whodunnit 'Worker::WithdrawCoin' do
            withdraw.update_columns(txid: txid, done_at: Time.current)

            # withdraw.succeed! will start another transaction, cause
            # Account after_commit callbacks not to fire
            withdraw.succeed
            withdraw.save!
          end
        end
      end
    rescue StandardError => e
      Rails.logger.info { "Failed to process #{withdraw.currency} withdraw with ID #{withdraw.id}: #{e.inspect}." }
      withdraw.fail!
    ensure
    end
  end
end
