desc "Calculates duration for all TimeSheets"
task :timesheet_calculate_duration => :environment do
  updated_count = 0
  limit = 1000
  offset = 0
  total_count = TimeSheet.count
  while offset <= total_count
    p offset
    TimeSheet.limit(limit).skip(offset).each do |time_sheet|
      time_sheet.duration = TimeSheet.calculate_working_minutes(time_sheet) if time_sheet.is_from_time_and_to_time_present?
      if time_sheet.save
        updated_count += 1
      end
    end
    offset += limit
  end
  p "Total Timesheets count = #{TimeSheet.count}"
  p "Total updated timesheets = #{updated_count}"
end
