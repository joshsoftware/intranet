FactoryGirl.define do
  factory :user_project do
    start_date { DateTime.now - 1 }
    end_date { nil }
    allocation { 100 }
    active { true }
    user
    project
  end
end
