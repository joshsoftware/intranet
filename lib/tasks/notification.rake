namespace :notification do
  desc "Email notification"
  
  task :birthday => :environment do
    User.send_birthdays_wish
  end

  task :year_of_completion => :environment do
    User.send_year_of_completion
  end
end
