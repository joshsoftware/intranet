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

  desc 'Update division column for all users'
  task update_division: :environment do
    User.employees.where(:status.ne => STATUS[:resigned]).each do |user|
      if user.location == LOCATIONS[0] # Bengaluru
        user.employee_detail.set(division: DIVISION_TYPES[:digital])
      elsif MANAGEMENT.include?(user.role)
        user.employee_detail.set(division: DIVISION_TYPES[:management])
      else
        user.employee_detail.set(division: DIVISION_TYPES[:project])
      end

      puts "Changing Division of user email: #{user.email} as #{user.employee_detail.division}"
    end
  end

  desc "Set division value as consultant for employees having '.jc@joshsoftware.com' as a part of email-id"
  task set_division_for_consultant: :environment do
    User.employees.where(:status.ne => STATUS[:resigned], email: /\.jc@joshsoftware\.com$/).each do |user|
      user.employee_detail.set(division: DIVISION_TYPES[:consultant])
      puts "Changing Division of user email: #{user.email} as #{user.employee_detail.division}"
    end
  end

  desc 'Update number of days count for leaves which overlaps optional holidays' +
       ' And availble leaves for respective employee'
  task update_leave_count: :environment do
    user_list = []
    User.each do |u|
      optional_holidays = HolidayList.where(
        holiday_type: 'OPTIONAL',
        :holiday_date.gte => Date.today.beginning_of_year,
        country: u.country
      )
      applied_optional_leaves = u.leave_applications.unrejected.where(
        leave_type: 'OPTIONAL',
        :start_at.gte => Date.today.beginning_of_year
      ).pluck(:start_at)
      optional_holidays.each do |o|
        leaves = u.leave_applications.where(
          :start_at.lte => o.holiday_date,
          :end_at.gte => o.holiday_date,
          leave_type: 'LEAVE'
        )
        leaves.each do |leave|
          number_of_days_count = 0
          (leave.start_at..leave.end_at).each do |date|
            number_of_days_count += 1 if !HolidayList.is_holiday?(date, u.country) || (HolidayList.is_optional_holiday?(date) && !applied_optional_leaves.include?(date))
          end
          user_list << [u.email, leave.id] if number_of_days_count != leave.number_of_days
        end
      end
    end
    puts "Email \t | Leave start at | Leave end at | Number of days | Updated number of days |  Available leave | Updated available leave"
    user_list.each do |user|
      leave = LeaveApplication.where(id: user[1]).first
      employee_detail = User.where(email: user[0]).first.employee_detail
      if leave.leave_status == REJECTED
        leave.update_attributes(number_of_days: leave.number_of_days + 1)
        puts "#{user[0]} \t | #{leave.start_at} | #{leave.end_at} | #{leave.number_of_days} | #{leave.number_of_days + 1} | #{employee_detail.available_leaves} | #{employee_detail.available_leaves}"
      else
        leave.update_attributes(number_of_days: leave.number_of_days + 1)
        employee_detail.update_attributes(available_leaves: employee_detail.available_leaves - 1)
        puts "#{user[0]} \t | #{leave.start_at} | #{leave.end_at} | #{leave.number_of_days} | #{leave.number_of_days + 1} | #{employee_detail.available_leaves} | #{employee_detail.available_leaves - 1}"
      end
    end
  end
end

def calculate_emp_id
  employee_id_array = User.distinct('employee_detail.employee_id').map!(&:to_i)
  employee_ids = employee_id_array.select { |id| id <= 8000}
  employee_ids.empty? ? 0 : employee_ids.max
end