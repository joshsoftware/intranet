FactoryGirl.define do
  factory :user do |u|
    u.role 'Employee'
    u.email "test@joshsoftware.com"
    u.password "test123"

  end
end
