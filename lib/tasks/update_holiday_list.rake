desc 'Update previous holidays type and country'
task update_holiday_list: :environment do
  holidays = HolidayList.where(holiday_type: nil, country: nil)
  holidays.each { |h| puts "Date: #{h.holiday_date}, Reason: #{h.reason}" }
  puts holidays.update_all(
    country: COUNTRIES[:india],
    holiday_type: HolidayList::MANDATORY
  )
end
