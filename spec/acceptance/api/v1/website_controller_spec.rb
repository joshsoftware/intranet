require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource "Website Apis" do
  let!(:projects) { FactoryGirl.create_list(:project,
      3,
      visible_on_website: true
    )
  }

  get "/api/v1/team" do
    example "Get all the team members" do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      leaders = FactoryGirl.create_list(:admin_with_designation,
        2,
        status: 'approved',
        visible_on_website:  true
      )
      members = FactoryGirl.create_list(:user_with_designation,
        3,
        status: 'approved',
        visible_on_website:  true
      )
      user = FactoryGirl.create(:user, email: "emp0@#{ORGANIZATION_DOMAIN}", visible_on_website: false)

      do_request
      res = JSON.parse(response_body)
      res["leaders"] = res["leaders"].sort_by { |user| user["email"] }
      res["members"] = res["members"].sort_by { |user| user["email"] }
      expect(status).to eq 200
      expect(res["leaders"].count).to eq 2
      expect(res["leaders"].last.keys).to eq ["email", "public_profile", "employee_detail"]
      expect(res["leaders"].last["employee_detail"]["designation"].keys).to eq ["name"]
      expect(res["leaders"].last["employee_detail"]["designation"]["name"]).
        to eq leaders.last.employee_detail.designation.name
      expect(res["leaders"].flatten).not_to include user.name
      expect(res["members"].count).to eq 3
      expect(res["members"].last.keys).to eq ["email", "public_profile", "employee_detail"]
      expect(res["members"].flatten).not_to include user.name
      expect(res["members"].last["employee_detail"]["designation"].keys).to eq ["name"]
      expect(res["members"].last["employee_detail"]["designation"]["name"]).
        to eq members.last.employee_detail.designation.name
    end

    example "Must be Unauthorized for referer other than #{ORGANIZATION_DOMAIN}" do

      do_request
      expect(status).to eq 401
    end
  end

  get "/api/v1/portfolio" do
    example "Get all projects" do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      project = FactoryGirl.create(:project, visible_on_website: false)

      do_request
      res = JSON.parse(response_body)
      expect(status).to eq 200
      expect(res.last.keys).to eq [
        "description", "name", "url", "case_study_url", "tags", "image_url"
      ]
      expect(res.count).to eq 3
    end

    example "Must be Unauthorized for referer other than #{ORGANIZATION_DOMAIN}" do

      do_request
      expect(status).to eq 401
    end
  end

  get "/api/v1/news" do
    example "Get all news" do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      news = FactoryGirl.create_list(:news, 5)
      do_request
      res = JSON.parse(response_body)
      expect(status).to eq 200
      expect(res["news"]["2020"].count).to eq(5)
    end
  end

  post "/api/v1/contact_us" do
    example "Should have status created" do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      params = {}
      params['name'] = Faker::Name.name
      params['email'] = Faker::Internet.email
      ENV['RACK_ENV'] = 'test'

      do_request(:contact_us => params)
      expect(status).to eq(201)
    end

    example "Should have status unprocessable entity" do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      params = {}
      params['email'] = Faker::Internet.email

      do_request(:contact_us => params)
      expect(status).to eq(422)
    end
  end

  post "/api/v1/career" do
    example 'Should have status created' do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      params = {}
      params['first_name'] = Faker::Name.first_name
      params['last_name'] = Faker::Name.last_name
      params['email'] = Faker::Internet.email
      params['contact_number'] = Faker::PhoneNumber.phone_number
      params['current_company'] = Faker::Company.name
      params['current_ctc'] = '8 lakhs'
      params['linkedin_profile'] = Faker::Internet.url
      params['github_profile'] = Faker::Internet.url
      params['resume'] = fixture_file_upload('spec/fixtures/files/sample1.pdf')
      params['portfolio_link'] = Faker::Internet.url
      params['cover'] = fixture_file_upload('spec/fixtures/files/sample1.pdf')

      do_request(:career => params)
      expect(status).to eq(201)
    end

    example 'Should have status unprocessable entity' do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      params = {}
      params['first_name'] = Faker::Name.first_name
      params['last_name'] = Faker::Name.last_name
      params['email'] = Faker::Internet.email

      do_request(:career => params)
      expect(status).to eq(422)
    end
  end
end
