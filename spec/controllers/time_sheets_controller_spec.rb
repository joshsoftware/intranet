require 'rails_helper'

RSpec.describe TimeSheetsController, type: :controller do
  context 'create' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, name: 'England Hockey', display_name: 'England_Hockey') }
    before do
      user.public_profile.slack_handle = USER_ID
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Should success' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      post :create, params
      resp = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(resp['text']).to eq("*Timesheet saved successfully!*")
    end

    it 'should fail because validation trigger on timesheet data' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => 'England 14-07-2018  6 7 abcd efghigk lmnop' 
      }

      post :create, params
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'Check user is exists' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
    let!(:project) { FactoryGirl.create(:project, name: 'England Hockey', display_name: 'England_Hockey') }
    before do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Associate slack id to user' do
      params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'user_id' => USER_ID,
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }
      post :create, params
      expect(response).to have_http_status(:created)
    end
  end

  context 'Timesheet: Daily status' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }

    context 'command with date option' do
      before do
        stub_request(:post, "https://slack.com/api/chat.postMessage")
        UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now - 2, end_date: nil)
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      end

      it 'Should success : user worked on single project' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s,
          'command' => '/daily_status'
        }

        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
        expect(response).to have_http_status(:ok)
      end

      it 'Should success : user worked on multiple projects' do
        deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
        UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now, end_date: nil)
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

        user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                                to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s,
          'command' => '/daily_status'
        }
        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M* *Deal signal: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n2. Deal signal 11:00AM 12:00PM Today I finish the work \n")
      end

      it 'Should fail because invalid date' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/13/2018'
        }

        post :daily_status, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'command without date option' do
      before do
        UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now, end_date: nil)
        stub_request(:post, "https://slack.com/api/chat.postMessage")
      end

      it 'Should success : user worked single project' do
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
        expect(response).to have_http_status(:ok)
      end

      it 'Should success : user worked on multiple project' do
        deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
        UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now, end_date: nil)
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')

        user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                                date: Date.today, from_time: '11:00',
                                to_time: '12:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }
        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M* *Deal signal: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n2. Deal signal 11:00AM 12:00PM Today I finish the work \n")
      end

      it 'Should fail because timesheet not present' do
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today - 1, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        post :daily_status, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'index' do
    let!(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com', role: 'Admin') }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'Should success' do
      deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
      UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now, end_date: nil)
      UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now, end_date: nil)
      user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
      params = {from_date: Date.yesterday - 1, to_date: Date.today}
      sign_in user
      get :index, params
      expect(response).to have_http_status(200)
      should render_template(:index)
    end

    it 'Should fail because user is not authorized' do
      user = FactoryGirl.create(:user, email: 'vijay@joshsoftware.com', role: 'Employee')
      user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      params = {from_date: Date.yesterday - 1, to_time: Date.today}
      sign_in user
      get :index, params
      expect(response).to have_http_status(302)
    end
  end

  context 'Show' do
    let!(:user) { FactoryGirl.create(:user, email: 'abc@joshsoftware.com', role: 'Admin') }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'Should success' do
      deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
      UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now, end_date: nil)
      UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now, end_date: nil)
      user.time_sheets.create!(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create!(user_id: user.id, project_id: deal_signal.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
      params = {user_id: user.id, from_date: Date.yesterday - 1, to_time: Date.today}
      get :show, id: user.id, user_id: user.reload.id, from_date: Date.yesterday - 1, to_time: Date.today
      expect(response).to have_http_status(200)
      should render_template(:show)
    end
  end
  
  context 'Project report' do
    let!(:user_one) { FactoryGirl.create(:user, email: 'test1@joshsoftware.com', role: 'Admin') }
    let!(:user_two) { FactoryGirl.create(:user, email: 'test2@joshsoftware.com', role: 'Admin') }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }
    
    it 'Should success' do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/05/2018'.to_date)

      TimeSheet.create(user_id: user_one.id, project_id: project.id,
                              date: '10/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')

      TimeSheet.create(user_id: user_two.id, project_id: project.id,
                              date: '11/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')
      params = params = {from_date: Date.today.beginning_of_month.to_s, to_date: Date.today.to_s}
      sign_in user_one
      get :projects_report, params
      expect(response).to have_http_status(200)
      should render_template(:projects_report)
    end

    it 'Should fail because user is not authorized' do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      TimeSheet.create(user_id: user_one.id, project_id: project.id,
                              date: '10/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')
      params = params = {from_date: Date.today.beginning_of_month.to_s, to_date: Date.today.to_s}
      get :projects_report, params
      expect(response).to have_http_status(302)
    end
  end
end
