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

every :month, :at => '12:30am' do
  rake "leave:increment_paid"
end

every :year, :at => '12:30am' do
  rake "leave:reset_leave_yearly"
end

every :day, :at => '10:00am' do
  rake "notification:birthday"
end

every :day, :at => '10:00am' do
  rake "notification:year_of_completion"
end
