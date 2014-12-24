# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :policy do
    title 'New Article'
    is_published true
    content "welcome"
  end
end
