# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project do
    name "Intranet"
    code_climate_id "12345"
    code_climate_snippet "Intranet Snipate Text"
  end
end
