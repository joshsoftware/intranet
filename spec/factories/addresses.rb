# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :address do
    flat_or_house_no '1'
    building_or_society_name 'Test Society'
    road 'Test Road'
    locality 'Test locality'
    city 'Test City'
    state 'Test State'
    phone_no '1234567890'
  end
end
