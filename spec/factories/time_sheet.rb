FactoryGirl.define do
  factory :time_sheet do
    date { Date.today - 1 }
    description { Faker::Lorem.sentences(2) }
    user
    project
    after(:build) do |obj|
      obj.from_time = "#{obj.date} 10:00" if obj.from_time == nil
      obj.to_time = "#{obj.date} 11:00" if obj.to_time == nil
    end
  end
end