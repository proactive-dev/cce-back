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

end
