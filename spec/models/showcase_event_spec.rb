require 'spec_helper'

describe ShowcaseEvent do
  context 'Validations' do
    it 'should success' do
      showcase_event = FactoryGirl.create(:showcase_event)
      expect(showcase_event.valid?).to eq(true)
    end

    it 'should fail because Name is nil' do
      showcase_event = FactoryGirl.build(:showcase_event, name: nil)
      expect(showcase_event.valid?).to eq(false)
      expect(showcase_event.errors.full_messages).to eq(["Name can't be blank"])
    end

    it 'should fail because Type is nil' do
      showcase_event = FactoryGirl.build(:showcase_event, type: nil)
      expect(showcase_event.valid?).to eq(false)
      expect(showcase_event.errors.full_messages).to eq(["Type can't be blank", "Type is not included in the list"])
    end

    it 'should fail because Description is nil' do
      showcase_event = FactoryGirl.build(:showcase_event, description: nil)
      expect(showcase_event.valid?).to eq(false)
      expect(showcase_event.errors.full_messages).to eq(["Description can't be blank"])
    end

    it 'should fail because Date is nil' do
      showcase_event = FactoryGirl.build(:showcase_event, date: nil)
      expect(showcase_event.valid?).to eq(false)
      expect(showcase_event.errors.full_messages).to eq(["Date can't be blank"])
    end

    it 'should fail because Venue is nil' do
      showcase_event = FactoryGirl.build(:showcase_event, venue: nil)
      expect(showcase_event.valid?).to eq(false)
      expect(showcase_event.errors.full_messages).to eq(["Venue can't be blank"])
    end

    it 'should raise error if Type is wrong' do
      showcase_event = FactoryGirl.build(:showcase_event, type: 'Faulty')
      expect(showcase_event.valid?).to eq(false)
      expect(showcase_event.errors.full_messages).to eq(["Type is not included in the list"])
    end

    it { is_expected.to validate_uniqueness_of(:name) }
  end

  it {should accept_nested_attributes_for(:showcase_event_applications)}
  it {should accept_nested_attributes_for(:showcase_event_teams)}

  it 'must return all Hackathons' do
    showcase_event1 = FactoryGirl.create(:showcase_event, type: 'Hackathon')
    showcase_event2 = FactoryGirl.create(:showcase_event, type: 'Community')
    hackathons = ShowcaseEvent.hackathons
    expect(hackathons.count).to eq(1)
    expect(hackathons[0]).to eq(showcase_event1)
  end

  it 'must return all Community Events' do
    showcase_event1 = FactoryGirl.create(:showcase_event, type: 'Hackathon')
    showcase_event2 = FactoryGirl.create(:showcase_event, type: 'Community')
    community_events = ShowcaseEvent.community_events
    expect(community_events.count).to eq(1)
    expect(community_events[0]).to eq(showcase_event2)
  end

  it "should return records to be displayed on website" do
    FactoryGirl.create(:showcase_event, type: 'Hackathon', showcase_on_website: true)
    FactoryGirl.create(:showcase_event, type: 'Community')
    showcase_events = ShowcaseEvent.showcase_on_website
    expect(showcase_events.count).to eq(1)
  end
end
