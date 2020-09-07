FactoryGirl.define do
  factory :open_source_project do
    name { Faker::App.name }
    description { Faker::Lorem.paragraph(5, false, 4) }
    url { Faker::Internet.url }
  end
end
