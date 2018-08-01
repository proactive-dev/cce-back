namespace :coin do
  desc "Add new accounts for new currency to already existing Members"
  task new_accounts: :environment do
    Member.all.each do |member|
      member.touch_accounts
    end
  end

  desc "Sync coin deposit transactions"
  task sync_deposit: :environment do
    code    = ENV['code']
    account = 'payment'
    number  = ENV['number'] ? ENV['number'].to_i : 100
    channel = DepositChannel.find_by_currency(code)

    if channel.blank?
      puts "Can not find the deposit channel by code: #{code}"
      exit 0
    end

    missed = []
    CoinAPI[code].listtransactions(account, number).each do |tx|
      next if tx['category'] != 'receive'

      unless PaymentTransaction::Normal.where(txid: tx['txid'], address: tx['address']).first
        puts "#{code} --- Missed txid:#{tx['txid']} address:#{tx['address']} (#{tx['amount']})"
        missed << tx
      end
    end
    puts "#{code} --- #{missed.size} missed transactions found."

    if ENV['reprocess'] == '1' && missed.size > 0
      puts "#{code} --- Reprocessing .."
      missed.each do |tx|
        AMQPQueue.enqueue :deposit_coin, { txid: tx['txid'], channel_key: channel.key }
      end
      puts "#{code} --- Done."
    end
  end
end
