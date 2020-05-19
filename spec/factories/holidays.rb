FactoryGirl.define do
  factory :holiday, class: HolidayList do
    reason { Faker::Lorem.sentence(4) }

    after(:build) do |obj|
      obj.holiday_date = Date.tomorrow
      obj.holiday_date = obj.holiday_date - 2.days if obj.holiday_date.saturday? || obj.holiday_date.sunday?
    end
  end

  # Make sure holiday_date is not a weekend
  factory :holiday_for_time_sheet, class: HolidayList do
    reason { Faker::Lorem.sentence(4)}
  end
end
