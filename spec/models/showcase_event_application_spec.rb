require 'spec_helper'

describe ShowcaseEventApplication do
  context 'Validations' do
    it 'should success' do
      showcase_event_application = FactoryGirl.create(:showcase_event_application)
      expect(showcase_event_application.valid?).to eq(true)
    end

    it 'should fail because Name is nil' do
      showcase_event_application = FactoryGirl.build(:showcase_event_application, name: nil)
      expect(showcase_event_application.valid?).to eq(false)
      expect(showcase_event_application.errors.full_messages).to eq(["Name can't be blank"])
    end

    it 'should fail because Description is nil' do
      showcase_event_application = FactoryGirl.build(:showcase_event_application, description: nil)
      expect(showcase_event_application.valid?).to eq(false)
      expect(showcase_event_application.errors.full_messages).to eq(["Description can't be blank"])
    end

    it 'should fail because Domain is nil' do
      showcase_event_application = FactoryGirl.build(:showcase_event_application, domain: nil)
      expect(showcase_event_application.valid?).to eq(false)
      expect(showcase_event_application.errors.full_messages).to eq(["Domain can't be blank"])
    end
  end

  context 'Name' do
    it 'should fail if Application Name already present for an Event' do
      showcase_event = FactoryGirl.create(:showcase_event)
      showcase_event_application = FactoryGirl.create(:showcase_event_application, name: 'Alpha', showcase_event: showcase_event)
      expect(showcase_event_application.valid?).to eq(true)
      showcase_event_application = FactoryGirl.build(:showcase_event_application, name: 'Alpha', showcase_event: showcase_event)
      expect(showcase_event_application.valid?).to eq(false)
      expect(showcase_event_application.errors.full_messages).to eq(["Name already present for Event"])
    end

    it 'should pass if Application Name same for different Event' do
      showcase_event1 = FactoryGirl.create(:showcase_event)
      showcase_event2 = FactoryGirl.create(:showcase_event)
      showcase_event_application = FactoryGirl.create(:showcase_event_application, name: 'Shoptok', showcase_event: showcase_event1)
      expect(showcase_event_application.valid?).to eq(true)
      showcase_event_application = FactoryGirl.build(:showcase_event_application, name: 'Shoptok', showcase_event: showcase_event2)
      expect(showcase_event_application.valid?).to eq(true)
    end
  end
end
