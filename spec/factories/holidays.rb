FactoryGirl.define do
  factory :holiday, class: HolidayList do
    reason { Faker::Lorem.sentence(4) }

    after(:build) do |obj|
      if(obj.holiday_date == nil)
        obj.holiday_date = Date.tomorrow
        obj.holiday_date = obj.holiday_date - 2.days if obj.holiday_date.saturday? || obj.holiday_date.sunday?
      end
    end
  end
end
