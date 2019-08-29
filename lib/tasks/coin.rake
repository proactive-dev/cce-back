namespace :coin do
  desc "Add new accounts for new currency to already existing Members"
  task new_accounts: :environment do
    Member.all.each do |member|
      member.touch_accounts
    end
  end

  desc "Add new margin_accounts for new currency to already existing Members"
  task new_margin_accounts: :environment do
    Member.all.each do |member|
      member.touch_margin_accounts
    end
  end

  desc "Add new lending_accounts for new currency to already existing Members"
  task new_lending_accounts: :environment do
    Member.all.each do |member|
      member.touch_lending_accounts
    end
  end

  desc "Write addresses to redis (for deposit)"
  task cache_addresses: :environment do
    Global.cache_addresses('eth')
    Global.cache_addresses('etc')
  end

  desc "Write tx_ids to redis"
  task cache_txs: :environment do
    Global.cache_txs
  end

  desc "Claim neo gas and divide into per member."
  task claim_neo_gas: :environment do
    total = Account.locked_sum('neo') + Account.balance_sum('neo')
    next if total <= 0

    gas = CoinAPI['neo'].unclaimed_gas
    available_gas = gas.fetch('available').to_d
    next if available_gas <= 0

    result = CoinAPI['neo'].claim_gas
    puts result

    Member.all.each do |member|
      neo_account = member.get_account('neo')
      amount = neo_account.balance + neo_account.locked
      next if amount <= 0

      gas_account = member.get_account('gas')
      gas_account.plus_funds(available_gas * amount / total, reason: Account::CLAIM_GAS)
    end
  end

end
