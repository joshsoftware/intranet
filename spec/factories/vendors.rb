FactoryGirl.define do
  factory :vendor do
    company { Faker::Company.name }
    category { 'Medical Insurance' }
  end
end
