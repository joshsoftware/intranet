require 'spec_helper'

describe Repository do
  context 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:host) }
    it { is_expected.to validate_inclusion_of(:host).to_allow(Repository::HOSTS) }
  end

  it 'should create a Repository' do
    project = FactoryGirl.create(:project)
    repository = FactoryGirl.create(:repository, project: project)
    expect(repository).to be_valid
  end

  it 'should not create a Repository' do
    repository = FactoryGirl.build(:repository)
    repository.save
    expect(repository).to be_invalid
    expect(repository.errors.full_messages).to eq(["Project can't be blank"])
  end

  context 'Trigger - should call code monitor service' do
    it 'when Repository is added' do
      project = FactoryGirl.create(:project)
      repository = FactoryGirl.build(:repository, project: project)
      params = {
        event_type:         'Repository Added',
        repository_id:      repository.id,
        repository_url:     repository.url,
        project_id:         repository.project.id,
        repository_details: repository.as_json({
          only: [
            :name, :host, :code_climate_id, :maintainability_badge,
            :test_coverage_badge, :visibility, :rollbar_access_token
          ]
        })
      }
      uri = URI('http://localhost')
      uri.query = URI.encode_www_form(params)
      stub_request(:get, uri).
        with(
          headers: {
            'Accept'=>'*/*',
            'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})
      expect(repository.new_record?).to eq(true)
      repository.save
      expect(repository).to be_valid
    end

    it 'when Repository is removed' do
      project = FactoryGirl.create(:project)
      repository = FactoryGirl.create(:repository, project: project)
      params = {
        event_type:         'Repository Removed',
        repository_id:      repository.id,
        repository_url:     repository.url,
        project_id:         repository.project.id
      }
      uri = URI('http://localhost')
      uri.query = URI.encode_www_form(params)
      stub_request(:get, uri).
        with(
          headers: {
            'Accept'=>'*/*',
            'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})
      repository.destroy
      expect(Repository.count).to eq 0
    end
  end

  it 'should not create a Repository with invalid host' do
    project = FactoryGirl.create(:project)
    repository = FactoryGirl.build(:repository, project: project)
    repository.host = 'invalid_string'
    repository.save
    expect(repository).to be_invalid
    expect(repository.errors.full_messages).to eq(["Host is not included in the list"])
  end

  it 'on delete repository, its associated code_climate_statistics should get deleted' do
    project = create(:project)
    repository = create(:repository, project: project)
    code_climate_statistic = create(:code_climate_statistic, repository: repository)
    expect(repository.code_climate_statistics.count).to eq(1)
    repository.destroy
    expect(repository.code_climate_statistics.count).to eq(0)
  end
end
