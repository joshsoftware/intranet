namespace :leave do
  desc "Monthly Paid Leave Update"
  
  task :increment_paid => :environment do
    MonthlyPaidLeaveWorker.perform_async()
  end

   task :reset_leave_yearly => :environment do
    ResetLeaveYearlyWorker.perform_async()
  end

  task :initial_seed => :environment do
    require 'csv'
    CSV.foreach("#{Rails.root}/doc/leave_initial_seed.csv", :headers => true) do|csv| 
      user = User.where(email: csv["email id"]).first
      if user
        leave_detail = user.leave_details.find_or_initialize_by(year: Date.today.year) 
        leave_detail.available_leave["Sick"] = csv["Sick Leave"].to_i
        leave_detail.available_leave["Casual"] = csv["Casual Leave"].to_i
        leave_detail.available_leave["TotalPrivilege"] = csv["Paid Leave"].to_i
        leave_detail.available_leave["CurrentPaid"] = 0
        leave_detail.save
      end
    end
  end
  
  task :change_available_leave_column => :environment do
    LeaveDetail.all.each do|leave_detail|
      leave_detail.available_leave["CurrentPrivilege"] = leave_detail.available_leave["CurrentPaid"]
      leave_detail.available_leave["TotalPrivilege"] = leave_detail.available_leave["TotalPaid"]
      leave_detail.save
    end
  end

  task :split_date => :environment do
    User.all.each do |user|
      user.set_details("doj", user.private_profile.date_of_joining)
      user.set_details("dob", user.public_profile.date_of_birth)
    end
  end
end
