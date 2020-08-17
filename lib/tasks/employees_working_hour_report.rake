desc 'Send timesheet report of employees who worked more than 9 hours a day over last week'
task :employees_working_hour_report => :environment do
  dates = 7.days.ago.to_date..(Date.today - 1)
  duration = 540 # mintues
  TimeSheet.generate_and_send_employees_working_hour_report(dates, duration)
end
