FactoryGirl.define do
  factory :time_sheet do
    date { Date.today - 1 }
    from_time { "#{date} 10:00" }
    to_time { "#{date} 11:00" }
    duration { 60 }
    description { Faker::Lorem.sentences(2) }
    user
    project
  end
end
