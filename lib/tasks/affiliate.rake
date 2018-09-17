namespace :affiliate do
  desc "Check and update state of affiliations"
  task check_status: :environment do
    Affiliation.wait.each do |affiliation|
      affiliation.check
    end
  end
end
