FactoryGirl.define do
  factory :employee_project_transfer do
    requested_date { Date.today }
    start_date { Date.today }
    status { PENDING }
    allocation { 100 }
    request_reason { 'Need someone experienced' }
  end
end
