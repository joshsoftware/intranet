require 'rails_helper'

RSpec.describe EntryPass, type: :model do
  it { should have_field(:date)}
  it { should belong_to(:user)}
  it { should validate_presence_of(:date) }

  context "validate daily limit" do
    it "should create entry pass if entries are not full" do
      entry_pass = FactoryGirl.build(:entry_pass)
      expect(entry_pass.valid?).to eq(true)
    end

    it "should not create entry pass if entries are full" do
      FactoryGirl.create_list(:entry_pass, DAILY_OFFICE_ENTRY_LIMIT)
      entry_pass = FactoryGirl.build(:entry_pass)
      expect(entry_pass.valid?).to eq(false)
      expect(entry_pass.errors[:date]).
        to eq(["Maximum number of employees allowed to work from office is reached"])
    end
  end
end
