FactoryGirl.define do
  factory :entry_pass do
    user
    date { Date.today }
  end
end
