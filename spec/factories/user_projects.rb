FactoryGirl.define do
  factory :user_project do
    start_date { Date.today }
    end_date { Date.today + 6.month }
    allocation { 160 }
    active { true }
    user
    project
  end
end
