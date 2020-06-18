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

  it 'should validate uniqueness of date for specific user' do
    user = FactoryGirl.create(:user)
    FactoryGirl.create(:entry_pass, user: user, date: Date.today)
    entry_pass = FactoryGirl.build(:entry_pass, user: user, date: Date.today)
    entry_pass.valid?
    expect(entry_pass.errors.full_messages).to eq(["Date already selected"])
  end
end
