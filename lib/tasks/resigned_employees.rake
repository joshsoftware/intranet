namespace :resigned_employees do
  desc 'Reject all leaves of resigned employees'
  task reject_future_leaves: :environment do
    User.where(status: STATUS[:resigned]).each do |user|
      user.reject_future_leaves
      p user.email
    end
  end

  desc 'Remove resigned employees from notification emails, UserProject and manager_ids of Project'
  task remove_from_project_records_and_notification_emails: :environment do
    User.where(status: STATUS[:resigned]).each do |user|
      user.set_user_project_entries_inactive
      user.remove_from_manager_ids
      user.remove_from_notification_emails
      p user.email
    end
  end

  desc 'Change status of resigned employees from pending to resigned'
  task change_status_of_resigned_employees: :environment do
    puts 'Following employees status has been changed from pending to resigned'
    users = User.employees.where(
      'employee_detail.date_of_relieving': {'$ne': nil, '$lt': Date.today}
    )
    
    users.each do |user|
      if user.employee_detail.date_of_relieving.present?
        puts "Email: #{user.email} DOR: #{user.employee_detail.date_of_relieving}"
        user.set(status: STATUS[:resigned])
        user.set_user_project_entries_inactive
      end
    end
  end
end
