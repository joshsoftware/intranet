desc 'Send weekly timesheet report to managers'
task :weekly_timesheet_report => :environment do
  from_date = Date.today - 7.days
  to_date = Date.today - 1.days
  managers = User.where("$or" => [{role: 'Manager'}, {role: 'Admin'}], status: STATUS[2])
  TimeSheet.get_project_and_generate_weekly_report(managers, from_date, to_date)
end
