FactoryGirl.define do
  factory :showcase_event do
    name { Faker::App.name }
    description { Faker::Lorem.paragraph(5, false, 4) }
    type { 'Hackathon' }
    date { Date.today }
    venue { 'Online' }
  end
end
