require 'rails_helper'

RSpec.describe FutureTeam, type: :model do
  context 'Validations' do
    it { is_expected.to validate_presence_of(:customer) }
    it { is_expected.to validate_presence_of(:years_of_experience) }
    it { is_expected.to validate_presence_of(:skills) }
    it { is_expected.to validate_presence_of(:number_of_open_positions) }
    it { is_expected.to validate_presence_of(:requirement_received_on) }
    it { is_expected.to validate_presence_of(:required_by_date) }
    it { is_expected.to validate_presence_of(:current_status) }
  end

  it 'should validate requirement_received_on date' do
    future_team = FactoryGirl.build(:future_team, requirement_received_on: Date.today + 1.days)
    future_team.valid?
    expect(future_team.errors.messages.blank?).to eq(false)
  end

  it 'should validate required_by_date' do
    future_team = FactoryGirl.build(:future_team, required_by_date: Date.today - 1.days)
    future_team.valid?
    expect(future_team.errors.messages.blank?).to eq(false)
  end

  it 'should validate skills' do
    future_team = FactoryGirl.build(:future_team, skills: ["Apollo"])
    future_team.valid?
    expect(future_team.errors.messages.blank?).to eq(false)
  end

  context 'Generate report' do
    it 'should generate csv' do
      future_team = FactoryGirl.create(:future_team)
      csv = FutureTeam.to_csv
      expect(csv).to eq(
          "Customer,Years Of Experience,Skills,Number Of Open Positions,Requirement Received On,Required By Date,Current Status,Proposed Candidates\n#{future_team.customer},#{future_team.years_of_experience},#{future_team.skills.join(' | ')},#{future_team.number_of_open_positions},#{future_team.requirement_received_on},#{future_team.required_by_date},#{future_team.current_status},\"\"\n"
      )
    end
  end

  describe '#get_readable_record' do
    it 'should return readable record' do
      future_team = FactoryGirl.create(:future_team, proposed_candidates: [])
      readable_record = future_team.get_readable_record
      record =  {
                  id: future_team.id,
                  customer: future_team.customer,
                  years_of_experience: future_team.years_of_experience,
                  skills: future_team.skills.join(' | '),
                  number_of_open_positions: future_team.number_of_open_positions,
                  requirement_received_on: future_team.requirement_received_on,
                  required_by_date: future_team.required_by_date,
                  current_status: future_team.current_status,
                  proposed_candidates: ""
                }
      expect(readable_record).to eq(record)
    end
  end
end
