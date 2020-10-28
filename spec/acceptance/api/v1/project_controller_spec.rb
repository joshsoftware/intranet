require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource "Project Apis" do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:manager) { create(:manager) }
  let!(:employees) { create_list(:employee, 2) }
  let!(:project) { create(:project, company: create(:company), manager_ids: [ manager.id.to_s ]) }
  let!(:repository) { create(:repository, project_id: project.id) }
  get '/api/v1/projects' do
    example 'Get all Project details' do
      UserProject.create( user_id: employees.first.id,
                          project_id: project.id,
                          start_date: DateTime.now - 2 )
      
      UserProject.create( user_id: employees.last.id,
                          project_id: project.id,
                          start_date: DateTime.now - 2 )
      user_ids = [{ 'id' => manager.id.to_s, 'name' => manager.name },
                  { 'id' => employees.first.id.to_s, 'name' => employees.first.name },
                  { 'id' => employees.last.id.to_s, 'name' => employees.last.name }]

      do_request
      response = JSON.parse(response_body)
      resp_project = response['projects'].first
      expect(resp_project['id']).to eq project.id.to_s
      expect(resp_project['name']).to eq project.name
      expect(resp_project['repositories'].first['url']).to eq repository.url
      expect(resp_project['repositories'].first['host']).to eq repository.host
      expect(resp_project['active_users'].count).to eq 3
      expect(resp_project['active_users']).to eq user_ids
    end
  end
end