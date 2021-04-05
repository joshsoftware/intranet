require 'time_difference'
namespace :timesheet_reminder do
  desc 'Reminds employees to fill timesheet'
  task ts_reminders: :environment do
    COUNTRIES.values.each do |country|
      unless HolidayList.is_holiday?(Date.today, country)
        users = User.get_employees(country).get_approved_users_to_send_reminder
        TimeSheet.search_user_and_send_reminder(users)
      end
    end
  end

  desc 'Reminds if user has filled timesheet for project which is not assigned to him'
  task timesheet_for_different_project: :environment do
    TimeSheet.get_users_and_timesheet_who_have_filled_timesheet_for_different_project
  end
end
