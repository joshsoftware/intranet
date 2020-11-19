FactoryGirl.define do
  factory :future_team do
    customer { Faker::App.name }
    skills { ["Android", "Go"] }
    years_of_experience { Faker::Number.decimal(l_digits = 1, r_digits = 1) }
    current_status { "Open" }
    proposed_candidates { [] }
    requirement_received_on { Date.today - 1.months }
    required_by_date { Date.today + 15.days }
    number_of_open_positions { Faker::Number.number(digits = 2) }
  end
end
