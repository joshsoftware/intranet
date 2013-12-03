# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :public_profile do |p|
    #p.association :user
    first_name "fname"
    last_name "lname"
    gender "Male"
    mobile_number "1234567890"
    blood_group "A+"
    date_of_birth Date.today
  end
end
