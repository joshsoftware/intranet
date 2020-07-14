desc "Calculates duration for all TimeSheets"
task :timesheet_calculate_duration => :environment do
  updated_count = 0
  TimeSheet.all.each do |time_sheet|
    time_sheet.duration = TimeSheet.calculate_working_minutes(time_sheet) if time_sheet.is_from_time_and_to_time_present?
    if time_sheet.save
      updated_count += 1
    end
  end
  p "Total Timesheets count = #{TimeSheet.count}"
  p "Total updated timesheets = #{updated_count}"
end
