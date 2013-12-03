# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :private_profile do
  	pan_number 'ABCDE1234F'
  	personal_email "test@test.com"
  	passport_number "J8369854"
  	qualification  "B.E"
  	date_of_joining Date.new(2013, 01, 01)
  	work_experience "2"
  end
end
