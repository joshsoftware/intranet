FactoryGirl.define do
  factory :technology_detail do
    name { Faker::ProgrammingLanguage.name }
    version { Faker::App.version }
  end
end
