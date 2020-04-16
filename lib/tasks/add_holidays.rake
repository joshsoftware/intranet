require 'csv'

desc 'Add holidays in holiday list model'
task :add_holidays => [:environment] do

  csv = CSV.read(ENV['filename'], skip_blanks: true, headers: true)
  csv.each do |row|
    puts row['Holiday date']
    puts row['Holiday date'].class
    holiday = HolidayList.create(
      holiday_date: Date.parse(row['Holiday date']),
      holiday_type: row['Holiday type'],
      reason: row['Reason'],
      country: row['Country']
    )

    p "#{holiday.errors.messages}" unless holiday.valid?
  end
end
