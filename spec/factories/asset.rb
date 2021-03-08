FactoryGirl.define do
  factory :asset do
    name { 'Laptop' }
    model { 'Thinkpad' }
    type { ASSET_TYPES[:hardware] }
    serial_number { 'S0001' }
    date_of_issue { Date.today }
    date_of_recovery { Date.today + 6.months }
    valid_till { Date.today + 6.months }
    before_image { fixture_file_upload('spec/fixtures/files/sample1.png') }
    after_image { fixture_file_upload('spec/fixtures/files/sample1.png') }
    recovered { false }
  end
end
