FactoryGirl.define do
  factory :showcase_event_application do
    name { Faker::App.name }
    description { Faker::Lorem.paragraph(5, false, 4) }
    domain { 'E-Commerce' }
    showcase_event
  end
end
