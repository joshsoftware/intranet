# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end


# Learn more: http://github.com/javan/whenever
=begin
set :environment, :development

every :month, :at => 'start of the month at 00:01am' do
  runner "Leave.increment_leaves"
end
every :month, :at => '5:30am'  do
  runner "User.leave_details_every_month"
  end
every :year do
  runner "User.send_mail_to_admin"
  end
  every 1.day, :at => '5:30 am' do
  runner "User.email_of_probation"
end
every 1.day, :at => '5:30 am' do
runner "User.date_of_birth"
end
=end

set :output, {error: 'log/cron_error.log', standard: 'log/cron.log'}

every '30 0 1 1 *' do
  rake "leave:reset_leave_yearly"
end

every :day, :at => '10:00am' do
  rake "notification:birthday"
end

every :day, :at => '10:00am' do
  rake "notification:year_of_completion"
end

every :day, :at => '09:30am' do
  rake "leave_reminder:daily"
end

every '0 10 15 * *' do
  rake "light:remove_bounced_emails"
end

every :day, :at => '10:00pm' do
  rake "database_backup"
end

every :monday, :at => '09:30am' do
  rake "weekly_timesheet_report"
end

every :day, :at => '03:00pm' do
  rake "timesheet_reminder:ts_reminders"
end

every :monday, :at => '09:30am' do
  rake "user_without_timesheet:weekly_report"
end

every :month, :at => 'start of the month at 09:30am' do
  rake "user_without_timesheet:monthly_report"
end

every :month, :at => 'start of the month at 09:30am' do
  rake 'light_air:send_opt_out_users_report'
end

every :day, :at => '10:00am' do
  rake "timesheet_reminder:timesheet_for_diffrent_project"
end

every :day, :at => '09:30am' do
  rake "leave_reminder:pending_leave"
end

every :day, :at => '10:00am' do
  rake "probation_notification:probation_end"
end

every :sunday, :at => '11:00pm' do
  rake "weekly_codeclimate_statistics"
end

every :monday, :at => '09:00am' do
  rake "weekly_project_summary"
end

every :monday, :at => '09:00am' do
  rake "fetch_rollbar_statistics"
end

every :tuesday, :at => '09:00am' do
  rake 'weekend_timesheet_report'
end

every :day, :at => '00:05am' do
  rake "delete_data:soft_delete_entry_pass_old_entries"
end
