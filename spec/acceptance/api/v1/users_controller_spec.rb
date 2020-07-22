require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users Apis' do
  let!(:employee) { FactoryGirl.create(:user_with_designation, status: 'approved') }

  get '/api/v1/users' do
    example 'Get all User details' do
      do_request
      response = JSON.parse(response_body)
      users = response['users']
      expect(users.count).to eq 1
      expect(users.first['id']).to eq employee.id.to_s
      expect(users.first['name']).to eq employee.name
      expect(users.first['email']).to eq employee.email
      expect(users.first['role']).to eq employee.role
      expect(users.first['public_profile']['github_handle']).to eq employee.public_profile.github_handle
      expect(users.first['public_profile']['gitlab_handle']).to eq employee.public_profile.gitlab_handle
      expect(users.first['public_profile']['bitbucket_handle']).to eq employee.public_profile.bitbucket_handle
    end
  end
end