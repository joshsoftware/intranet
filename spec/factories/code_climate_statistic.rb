FactoryGirl.define do
  factory :code_climate_statistic do
    quality_gpa { Faker::Number.number }
    test_coverage { Faker::Number.number }
    lines_of_code { { Ruby: Faker::Number.number } }
    maintainability { Faker::Number.number }
    remediation_time { Faker::Number.number }
    technical_debt_ratio { Faker::Number.number }
    remarks { [Faker::Number.number] }
  end
end
