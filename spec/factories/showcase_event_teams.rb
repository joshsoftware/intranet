FactoryGirl.define do
  factory :showcase_event_team do
    name { Faker::App.name }
    proposed_solution { Faker::Lorem.paragraph(5, false, 4) }
    repository_link { Faker::Internet.url }
    demo_link { 'https://www.youtube.com/watch?v=SB15cKg7qP4' }
    showcase_event
    showcase_event_application
  end
end
