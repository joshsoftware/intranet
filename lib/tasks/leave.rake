namespace :leave do
  
  task :reset_leave_yearly => :environment do
    ResetLeaveYearlyWorker.perform_async()
  end

  task :split_date => :environment do
    User.all.each do |user|
      user.set_details("doj", user.private_profile.date_of_joining)
      user.set_details("dob", user.public_profile.date_of_birth)
    end
  end
end
