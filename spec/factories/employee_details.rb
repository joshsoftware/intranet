FactoryGirl.define do
  factory :employee_detail do
    designation
    location {"Pune"}
    available_leaves { 24 }
    notification_emails { ['hr@testcompany.com'] }
  end
end
