FactoryGirl.define do
  factory :entry_pass do
    user
    date { Date.today }
    details { "No Internet. 10:00 - 5:00" }
  end
end
