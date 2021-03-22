FactoryGirl.define do
  factory :bank_account do
    bank_name { Faker::Bank.name }
    account_number { Faker::Bank.account_number }
    name_on_passbook { Faker::Name.name }
    ifsc_code { Faker::Code.asin }
  end
end
