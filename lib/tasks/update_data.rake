namespace :update_data do
  desc 'Update type of project and billing frequency column'
  task update_project_fields: :environment do
    projects = Project.where(is_free: true).update_all(type_of_project: 'Free', billing_frequency: 'NA')
    projects = Project.where(is_free: false).update_all(type_of_project: 'T&M', billing_frequency: 'Monthly')
  end

  desc 'Update Leave Type column'
  task update_leave_type_field: :environment do
    LeaveApplication.update_all(leave_type: LeaveApplication::LEAVE)
  end

  desc 'Update notification emails column for users having notification emails value as nil'
  task update_notification_emails: :environment do
    User.where('employee_detail.notification_emails': nil).each do |user|
      puts "Changing notification_emails of user.email #{user.email}"
      user.employee_detail.set(notification_emails: [])
    end
  end

  desc 'Update employee id to have proper padding of 0'
  task update_employee_id: :environment do
    User.nin('employee_detail.employee_id': [nil, '']).each do |user|
      employee_id = user.employee_detail.employee_id
      updated_employee_id = employee_id.rjust(3, '0')
      if employee_id != updated_employee_id
        puts "Changing employee id of employee.email #{user.email} - changes '#{employee_id}' to '#{updated_employee_id}'"
        user.employee_detail.set(employee_id: updated_employee_id)
      end
    end
  end

  desc 'Update employee ids of Bengaluru employees'
  task update_bengaluru_employee_ids: :environment do
    puts "Email \t | Previous EmpId | Current EmpId"
    User.where('employee_detail.location': LOCATIONS[0]).each do |user|
      if user.employee_detail.employee_id.to_i > 8000
        emp_id = calculate_emp_id + 1
        puts "#{user.email} | #{user.employee_detail.employee_id} | #{emp_id}"
        user.employee_detail.set(employee_id: emp_id)
      end
    end
  end
end

def calculate_emp_id
  employee_id_array = User.distinct('employee_detail.employee_id').map!(&:to_i)
  employee_ids = employee_id_array.select { |id| id <= 8000}
  employee_ids.empty? ? 0 : employee_ids.max
end