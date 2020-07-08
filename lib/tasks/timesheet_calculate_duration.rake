desc "Calculates duration for all TimeSheets"
task :timesheet_calculate_duration => :environment do
  TimeSheet.all.each do |time_sheet|
    time_sheet.duration = TimeSheet.calculate_working_minutes(time_sheet) if time_sheet.is_from_time_and_to_time_present?
    time_sheet.save
  end
end
