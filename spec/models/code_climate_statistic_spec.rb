require 'spec_helper'

describe CodeClimateStatistic do
  it 'should create a CodeClimateStatistic' do
    project = FactoryGirl.create(:project)
    repository = FactoryGirl.create(:repository, project: project)
    code_climate_statistic = FactoryGirl.create(:code_climate_statistic, repository: repository)
    expect(code_climate_statistic).to be_valid
  end

  it 'should not create a CodeClimateStatistic without a repository' do
    code_climate_statistic = FactoryGirl.build(:code_climate_statistic)
    code_climate_statistic.save
    expect(code_climate_statistic.persisted?).to be_falsy
    expect(code_climate_statistic.valid?).to be_falsy
    expect(code_climate_statistic.errors.full_messages).to eq(["Repository can't be blank"])
  end
end
