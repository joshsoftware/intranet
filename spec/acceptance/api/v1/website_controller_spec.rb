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

  get "/api/v1/open_source_contributions" do
    example 'Should return open source projects' do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      open_source_project = FactoryGirl.create(:open_source_project, name: 'Shoptok', showcase_on_website: true)
      project = FactoryGirl.create(:project, name: 'Intranet', showcase_as_open_source: true)
      do_request
      res = JSON.parse(response_body)
      expected_response = {
        'projects' => [
          project.as_json({only: [:name, :description, :url], methods: [:case_study_url, :tags, :image_url]}),
          open_source_project.as_json({only: [:name, :description, :url], methods: [:case_study_url, :tags, :image_url]})
        ]
      }
      expect(status).to eq 200
      expect(res).to eq(expected_response)
    end
  end

  get "/api/v1/hackathons" do
    example 'Should return hackathon events' do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      hackathon = FactoryGirl.create(:showcase_event, showcase_on_website: true)
      showcase_event_application = FactoryGirl.create(:showcase_event_application, showcase_event: hackathon)
      member = FactoryGirl.create(:user)
      showcase_event_team = FactoryGirl.create(:showcase_event_team, showcase_event_application: showcase_event_application, member_ids: [member.id])
      do_request
      res = JSON.parse(response_body)
      expect(status).to eq 200
      expect(res['hackathons'][0]["name"]).to eq(hackathon.name)
      expect(res['hackathons'][0]["showcase_event_applications"].count).to eq(1)
      expect(res['hackathons'][0]["showcase_event_applications"][0]["name"]).to eq(showcase_event_application.name)
      expect(res['hackathons'][0]["showcase_event_applications"][0]["showcase_event_teams"].count).to eq(1)
      expect(res['hackathons'][0]["showcase_event_applications"][0]["showcase_event_teams"][0]["name"]).to eq(showcase_event_team.name)
    end
  end

  get "/api/v1/community_events" do
    example 'Should return community events' do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      community_event = FactoryGirl.create(:showcase_event, type: 'Community', showcase_on_website: true)
      do_request
      res = JSON.parse(response_body)
      expect(status).to eq 200
      expect(res['community_events'][0]["name"]).to eq(community_event.name)
      expect(res['community_events'][0]["venue"]).to eq(community_event.venue)
      expect(res['community_events'][0]["description"]).to eq(community_event.description)
    end
  end

  get "/api/v1/trainings" do
    example 'Should return all training records' do
      header 'Referer', "http://#{ORGANIZATION_DOMAIN}"
      training = FactoryGirl.create(:training, showcase_on_website: true)
      chapter = FactoryGirl.create(:chapter, training: training)
      do_request
      res = JSON.parse(response_body)
      expect(status).to eq 200
      expect(res['trainings'][0]["subject"]).to eq(training.subject)
      expect(res['trainings'][0]["objectives"]).to eq(training.objectives)
      expect(res['trainings'][0]["chapters"][0]["chapter_number"]).to eq(chapter.chapter_number)
      expect(res['trainings'][0]["chapters"][0]["subject"]).to eq(chapter.subject)
      expect(res['trainings'][0]["chapters"][0]["objectives"]).to eq(chapter.objectives)
    end
  end
end
