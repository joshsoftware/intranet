FactoryGirl.define do
  factory :project do
    name { Faker::App.name }
    code { Faker::Lorem.characters(10) }
    rails_version { Faker::App.semantic_version }
    ruby_version { Faker::App.semantic_version }
    database { 'MongoDB' }
    other_details { Faker::App.name }
    start_date { Date.today }
    end_date { Date.today + 6.month }
    billing_frequency 'Monthly'
    type_of_project 'T&M'
    batch_name 'Alpha'
    follow_client_holiday_calendar false

    association :company
  end
end
