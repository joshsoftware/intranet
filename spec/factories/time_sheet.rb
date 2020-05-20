FactoryGirl.define do
  factory :time_sheet do
    date { Date.today - 1 }
    from_time { Time.parse('10:00') - 24.hours }
    to_time { Time.parse('11:00') - 24.hours }
    description { Faker::Lorem.sentences(2) }
    user
    project
  end
end