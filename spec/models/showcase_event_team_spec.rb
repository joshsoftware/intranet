require 'spec_helper'

describe ShowcaseEventTeam do
  context 'Validations' do
    it 'should success' do
      showcase_event_team = FactoryGirl.create(:showcase_event_team)
      expect(showcase_event_team.valid?).to eq(true)
    end

    it 'should fail because Name is nil' do
      showcase_event_team = FactoryGirl.build(:showcase_event_team, name: nil)
      expect(showcase_event_team.valid?).to eq(false)
      expect(showcase_event_team.errors.full_messages).to eq(["Name can't be blank"])
    end

    it 'should fail because proposed_solution is nil' do
      showcase_event_team = FactoryGirl.build(:showcase_event_team, proposed_solution: nil)
      expect(showcase_event_team.valid?).to eq(false)
      expect(showcase_event_team.errors.full_messages).to eq(["Proposed solution can't be blank"])
    end

    it 'should fail because repository_link is nil' do
      showcase_event_team = FactoryGirl.build(:showcase_event_team, repository_link: nil)
      expect(showcase_event_team.valid?).to eq(false)
      expect(showcase_event_team.errors.full_messages).to eq(["Repository link can't be blank"])
    end

    it 'should fail because demo_link is nil' do
      showcase_event_team = FactoryGirl.build(:showcase_event_team, demo_link: nil)
      expect(showcase_event_team.valid?).to eq(false)
      expect(showcase_event_team.errors.full_messages).to eq(["Demo link can't be blank"])
    end
  end

  it {should accept_nested_attributes_for(:technology_details)}

  context 'Team Name' do
    it 'should fail if Team Name already present for an Event' do
      showcase_event = FactoryGirl.create(:showcase_event)
      showcase_event_team = FactoryGirl.create(:showcase_event_team, name: 'Alpha', showcase_event: showcase_event)
      expect(showcase_event_team.valid?).to eq(true)
      showcase_event_team = FactoryGirl.build(:showcase_event_team, name: 'Alpha', showcase_event: showcase_event)
      expect(showcase_event_team.valid?).to eq(false)
      expect(showcase_event_team.errors.full_messages).to eq(["Name already present for Event"])
    end

    it 'should pass if Team Name same for different Event' do
      showcase_event1 = FactoryGirl.create(:showcase_event)
      showcase_event2 = FactoryGirl.create(:showcase_event)
      showcase_event_team = FactoryGirl.create(:showcase_event_team, name: 'Alpha', showcase_event: showcase_event1)
      expect(showcase_event_team.valid?).to eq(true)
      showcase_event_team = FactoryGirl.build(:showcase_event_team, name: 'Alpha', showcase_event: showcase_event2)
      expect(showcase_event_team.valid?).to eq(true)
    end
  end
end
