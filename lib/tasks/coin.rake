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

end
