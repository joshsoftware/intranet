FactoryGirl.define do
  factory :news do |u|
    date { Date.today }
    title { Faker::Lorem.sentence }
    link { Faker::Internet.url }
    description { Faker::Lorem.paragraph(5, false, 4) }
    image_url { Faker::Internet.url }
  end
end
