require 'rails_helper'

RSpec.describe TimeSheetsController, type: :controller do

  #Slack related specs
  # context 'create' do
  #   let!(:user) { FactoryGirl.create(:user) }
  #   let!(:project) { FactoryGirl.create(:project) }
  #   before do
  #     user.public_profile.slack_handle = USER_ID
  #     FactoryGirl.create(:user_project,
  #       user: user,
  #       project: project,
  #       start_date: DateTime.now - 2
  #     )
  #     user.save
  #     stub_request(:post, "https://slack.com/api/chat.postMessage")
  #   end

  #   it 'Should success' do
  #     params = {
  #       'user_id' => USER_ID, 
  #       'channel_id' => CHANNEL_ID, 
  #       'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
  #     }

  #     post :create, params
  #     resp = JSON.parse(response.body)
  #     expect(response).to have_http_status(:created)
  #     expect(resp['text']).to eq("*Timesheet saved successfully!*")
  #   end

  #   it 'should fail because validation trigger on timesheet data' do
  #     params = {
  #       'user_id' => USER_ID, 
  #       'channel_id' => CHANNEL_ID, 
  #       'text' => 'England 14-07-2018  6 7 abcd efghigk lmnop' 
  #     }

  #     post :create, params
  #     expect(response).to have_http_status(:bad_request)
  #   end
  # end


  # context 'Check user is exists' do
  #   let(:user) { FactoryGirl.create(:user) }
  #   let!(:project) { FactoryGirl.create(:project) }
  #   before do
  #     FactoryGirl.create(:user_project,
  #       user: user,
  #       project: project,
  #       start_date: DateTime.now - 2
  #     )
  #     user.save
  #     stub_request(:post, "https://slack.com/api/chat.postMessage")
  #   end

  #   it 'Associate slack id to user' do
  #     params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'user_id' => USER_ID,
  #       'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
  #     }
  #     post :create, params
  #     expect(response).to have_http_status(:created)
  #   end
  # end

  # context 'Timesheet: Daily status' do
  #   let(:user) { FactoryGirl.create(:user) }
  #   let!(:tpn) { FactoryGirl.build(:project) }

  #   context 'command with date option' do
  #     before do
  #       tpn.name = 'The pediatric network'
  #       tpn.display_name = 'The_pediatric_network'
  #       tpn.save
  #       stub_request(:post, "https://slack.com/api/chat.postMessage")
  #       FactoryGirl.create(:user_project,
  #         user: user,
  #         project: tpn,
  #         start_date: DateTime.now - 2
  #       )
  #       FactoryGirl.create(:time_sheet,
  #         user: user,
  #         project: tpn,
  #         date: DateTime.yesterday,
  #         from_time: Time.parse("#{Date.yesterday} 9:00"),
  #         to_time: Time.parse("#{Date.yesterday} 10:00"),
  #         description: 'Today I finish the work'
  #       )
  #     end

  #     it 'Should success : user worked on single project' do
  #       params = {
  #         'user_id' => USER_ID,
  #         'channel_id' => CHANNEL_ID,
  #         'text' => Date.yesterday.to_s,
  #         'command' => '/daily_status'
  #       }

  #       post :daily_status, params
  #       resp = JSON.parse(response.body)
  #       expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
  #       expect(response).to have_http_status(:ok)
  #     end

  #     it 'Should success : user worked on multiple projects' do
  #       deal_signal = FactoryGirl.build(:project)
  #       deal_signal.name = 'Deal signal'
  #       deal_signal.display_name = 'deal_signal'
  #       deal_signal.save
  #       FactoryGirl.create(:user_project,
  #         user: user,
  #         project: deal_signal,
  #         start_date: DateTime.now - 4
  #       )
  #       FactoryGirl.create(:time_sheet,
  #         user: user,
  #         project: deal_signal,
  #         date: DateTime.yesterday,
  #         from_time: Time.parse("#{Date.yesterday} 11:00"),
  #         to_time: Time.parse("#{Date.yesterday} 12:00"),
  #         description: 'Today I finish the work'
  #       )
  #       params = {
  #         'user_id' => USER_ID,
  #         'channel_id' => CHANNEL_ID,
  #         'text' => Date.yesterday.to_s,
  #         'command' => '/daily_status'
  #       }
  #       post :daily_status, params
  #       resp = JSON.parse(response.body)
  #       expect(response).to have_http_status(:ok)
  #       expect(resp['text']).to eq(
  #         "You worked on *The pediatric network: 1H 00M* *Deal signal: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n2. Deal signal 11:00AM 12:00PM Today I finish the work \n"
  #       )
  #     end

  #     it 'Should fail because invalid date' do
  #       params = {
  #         'user_id' => USER_ID,
  #         'channel_id' => CHANNEL_ID,
  #         'text' => '06/13/2018'
  #       }

  #       post :daily_status, params
  #       expect(response).to have_http_status(:unprocessable_entity)
  #     end
  #   end

  #   context 'command without date option' do
  #     before do
  #       tpn.name = 'The pediatric network'
  #       tpn.display_name = 'The_pediatric_network'
  #       tpn.save
  #       FactoryGirl.create(:user_project,
  #         user: user,
  #         project: tpn,
  #         start_date: DateTime.now - 3
  #         )
  #       stub_request(:post, "https://slack.com/api/chat.postMessage")
  #     end

  #     it 'Should success : user worked single project' do
  #       FactoryGirl.create(:time_sheet,
  #         user: user,
  #         project: tpn,
  #         date: Date.today,
  #         from_time: '9:00',
  #         to_time: '10:00',
  #         description: 'Today I finish the work'
  #       )
  #       params = {
  #         'user_id' => USER_ID,
  #         'channel_id' => CHANNEL_ID,
  #         'text' => ""
  #       }

  #       post :daily_status, params
  #       resp = JSON.parse(response.body)
  #       expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
  #       expect(response).to have_http_status(:ok)
  #     end

  #     it 'Should success : user worked on multiple project' do
  #       deal_signal = FactoryGirl.build(:project)
  #       deal_signal.name = 'Deal signal'
  #       deal_signal.display_name = 'deal_signal'
  #       deal_signal.save
  #       FactoryGirl.create(:user_project,
  #         user: user,
  #         project: deal_signal,
  #         start_date: DateTime.now - 3
  #       )
  #       FactoryGirl.create(:time_sheet,
  #         user: user,
  #         project: tpn,
  #         date: Date.today,
  #         from_time: "#{Date.today} 7:00",
  #         to_time: "#{Date.today} 8:00",
  #         description: 'Today I finish the work'
  #       )

  #       FactoryGirl.create(:time_sheet,
  #         user: user,
  #         project: deal_signal,
  #         date: Date.today,
  #         from_time: "#{Date.today} 8:00",
  #         to_time: "#{Date.today} 9:00",
  #         description: 'Today I finish the work'
  #       )
  #       params = {
  #         'user_id' => USER_ID,
  #         'channel_id' => CHANNEL_ID,
  #         'text' => ""
  #       }
  #       post :daily_status, params
  #       resp = JSON.parse(response.body)
  #       expect(response).to have_http_status(:ok)
  #       expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M* *Deal signal: 1H 00M*. Details are as follow\n\n1. The pediatric network 07:00AM 08:00AM Today I finish the work \n2. Deal signal 08:00AM 09:00AM Today I finish the work \n")
  #     end

  #     it 'Should fail because timesheet not present' do
  #       FactoryGirl.create(:time_sheet,
  #         user: user,
  #         project: tpn,
  #         date: Date.today - 1,
  #         from_time: '9:00',
  #         to_time: '10:00',
  #         description: 'Today I finish the work'
  #       )
  #       params = {
  #         'user_id' => USER_ID,
  #         'channel_id' => CHANNEL_ID,
  #         'text' => ""
  #       }

  #       post :daily_status, params
  #       expect(response).to have_http_status(:unprocessable_entity)
  #     end
  #   end
  # end

  context 'index' do
    let!(:user) { FactoryGirl.create(:admin) }
    let!(:project1) { FactoryGirl.create(:project) }

    it 'Should success' do
      project2 = FactoryGirl.create(:project)
      FactoryGirl.create(:user_project,
        user: user,
        project: project1,
        start_date: DateTime.now - 3
      )
      FactoryGirl.create(:user_project,
        user: user,
        project: project2,
        start_date: DateTime.now - 3
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project1,
        date: DateTime.yesterday,
        from_time: "#{Date.yesterday} 9:00",
        to_time: "#{Date.yesterday} 10:00"
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project2,
        date: DateTime.yesterday,
        from_time: "#{Date.yesterday} 11:00",
        to_time: "#{Date.yesterday} 12:00"
      )
      params = {from_date: Date.yesterday - 1, to_date: Date.today}
      sign_in user
      get :index, params
      expect(response).to have_http_status(200)
      should render_template(:index)
    end

    it 'Should return user specific timesheet ' do
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:user_project,
        user: user,
        project: project1,
        start_date: Date.today - 3
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project1,
        date: DateTime.yesterday,
        from_time: "#{Date.yesterday} 9:00",
        to_time: "#{Date.yesterday} 10:00"
      )
      params = {from_date: Date.yesterday - 1, to_time: Date.today}
      sign_in user
      get :index, params
      expect(response).to have_http_status(200)
    end
  end

  context 'GET new' do
    it 'should respond with success' do
      user = FactoryGirl.create(:user)
      sign_in user
      get :new, { user_id: user.id }
      should respond_with(:success)
      should render_template(:new)
    end
  end

  context 'GET edit_timesheet' do
    before do
      @admin = FactoryGirl.create(:admin)
      @user1 = FactoryGirl.create(:employee)
      @user2 = FactoryGirl.create(:employee)
      @project = FactoryGirl.create(:project)
      @user_project = FactoryGirl.create(:user_project, user: @user1, project: @project)
      @timesheet = FactoryGirl.create(:time_sheet, user: @user1, project: @project)
    end

    it "should render edit_timesheet for own timesheets" do
      sign_in @user1
      get :edit_timesheet, { user_id: @user1.id, time_sheet_id: @timesheet.id, time_sheet_date: @timesheet.date }
      expect(response).to have_http_status(:success)
      should render_template(:edit_timesheet)
    end

    it "should render edit_timesheet for timesheets of any user if role is admin" do
      sign_in @admin
      get :edit_timesheet, { user_id: @user1.id, time_sheet_id: @timesheet.id, time_sheet_date: @timesheet.date }
      expect(response).to have_http_status(:success)
      should render_template(:edit_timesheet)
    end

    it 'should not render edit_timesheet for timesheets of other users if role is employee' do
      sign_in @user2
      get :edit_timesheet, { user_id: @user1.id, time_sheet_id: @timesheet.id, time_sheet_date: @timesheet.date }
      expect(response).to have_http_status(302)
      expect(flash[:error]).to eq("Invalid access")
      should redirect_to(users_time_sheets_path)
    end
  end

  context 'Show' do
    let!(:user) { FactoryGirl.create(:admin) }
    let!(:project1) { FactoryGirl.create(:project) }

    it 'users timesheet' do
      sign_in user
      project2 = FactoryGirl.create(:project)
      FactoryGirl.create(:user_project,
        user: user,
        project: project1,
        start_date: DateTime.now - 3
      )
      FactoryGirl.create(:user_project,
        user: user,
        project: project2,
        start_date: DateTime.now - 3
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project1,
        date: DateTime.yesterday,
        from_time: "#{Date.yesterday} 9:00",
        to_time: "#{Date.yesterday} 10:00"
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project2,
        date: DateTime.yesterday,
        from_time: "#{Date.yesterday} 11:00",
        to_time: "#{Date.yesterday} 12:00"
      )
      params = {
        user_id: user.id,
        from_date: Date.yesterday - 1,
        to_time: Date.today
      }
      get :users_timesheet, user_id: user.id,
        from_date: Date.yesterday - 1,
        to_date: Date.today
      expect(response).to have_http_status(200)
      should render_template(:users_timesheet)
    end

    context 'users_timesheet' do
      before do
        @employee = FactoryGirl.create(:employee)
        FactoryGirl.create(:time_sheet,
          project: project1,
          user: @employee,
          date: DateTime.yesterday,
          from_time: "#{Date.yesterday} 11:00",
          to_time: "#{Date.yesterday} 12:00"
        )
        FactoryGirl.create(:time_sheet,
          project: project1,
          user: @employee,
          date: DateTime.yesterday,
          from_time: "#{Date.yesterday} 14:00",
          to_time: "#{Date.yesterday} 16:00"
        )
      end

      it "should render users_timesheet of other users' if role admin or hr or super-admin" do
        sign_in user
        params = {
          user_id: @employee.id,
          from_date: Date.yesterday - 1,
          to_time: Date.today
        }
        get :users_timesheet, params
        expect(response).to have_http_status(:success)
        should render_template(:users_timesheet)
      end

      it "should not render users_timesheet of other users' if role employee" do
        employee2 = FactoryGirl.create(:employee)
        sign_in employee2
        params = {
          user_id: @employee.id,
          from_date: Date.yesterday - 1,
          to_time: Date.today
        }
        get :users_timesheet, params
        expect(response).to have_http_status(302)
        expect(flash[:error]).to eq("Invalid access")
        should redirect_to(time_sheets_path)
      end
    end
  end

  context 'Project report' do
    let!(:user_one) { FactoryGirl.create(:admin) }
    let!(:user_two) { FactoryGirl.create(:admin) }
    let!(:project) { FactoryGirl.create(:project) }
    
    it 'Should success' do
      FactoryGirl.create(:user_project,
        user: user_one,
        project: project,
        start_date: '01/08/2018'.to_date
      )
      FactoryGirl.create(:user_project,
        user: user_two,
        project: project,
        start_date: '05/09/2018'.to_date,
      )
      FactoryGirl.create(:time_sheet,
        user: user_one,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 9:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      FactoryGirl.create(:time_sheet,
        user: user_two,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 9:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      params = {
        from_date: Date.today.beginning_of_month.to_s,
        to_date: Date.today.to_s
      }
      sign_in user_one
      get :projects_report, params
      expect(response).to have_http_status(200)
      should render_template(:projects_report)
    end

    it 'Should fail because user is not authorized' do
      user_one.update_attributes(role: ROLE[:employee])
      FactoryGirl.create(:user_project,
        user: user_one,
        project: project,
        start_date: '01/08/2018'.to_date
      )
      FactoryGirl.create(:time_sheet,
        user: user_one,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 9:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      params = {
        from_date: Date.today.beginning_of_month.to_s,
        to_date: Date.today.to_s
      }
      sign_in user_one
      get :projects_report, params
      expect(response).to have_http_status(302)
    end
  end

  context 'Individual project report' do
    let!(:user) { FactoryGirl.create(:admin) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should success' do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: '01/08/2018'.to_date
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 9:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      sign_in user
      get :individual_project_report, id: project.id,
        from_date: '01/09/2018',
        to_date: '27/09/2018'
      expect(response).to have_http_status(200)
    end

    it 'Should fail because user is not authorized' do
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: '01/08/2018'.to_date
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 9:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      sign_in user
      get :individual_project_report, id: project.id,
        from_date: '01/09/2018',
        to_date: '27/09/2018'
      expect(response).to have_http_status(302)
    end
  end

  context 'Update' do
    let!(:user) { FactoryGirl.create(:admin) }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:employee) { FactoryGirl.create(:user) }

    context 'should successfully update timesheet' do
      it 'if all attributes are valid' do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10:00",
          to_time: "#{Date.today - 1} 11:30"
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 09:00",
              to_time: "#{Date.today - 1} 11:15",
              description: 'testing API and call with client',
              id: time_sheet.id
            }
          },
          id:user.id
        }
        put :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        expect(time_sheet.reload.from_time.to_s).
          to eq("#{Date.today - 1} - 09:00 AM")
        expect(time_sheet.reload.to_time.to_s).
          to eq("#{Date.today - 1} - 11:15 AM")
        expect(time_sheet.reload.description).
          to eq('testing API and call with client')
        expect(time_sheet.reload.updated_by).to eq(user.id.to_s)
      end

      it 'if duration is present' do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10:00",
          to_time: "#{Date.today - 1} 11:30"
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: nil,
              to_time: nil,
              duration: 120,
              description: 'testing API and call with client',
              id: time_sheet.id
            }
          },
          id:user.id
        }
        put :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        expect(time_sheet.reload.from_time).
          to eq(nil)
        expect(time_sheet.reload.to_time).
          to eq(nil)
        expect(time_sheet.reload.description).
          to eq('testing API and call with client')
        expect(time_sheet.reload.duration).
          to eq(120)
        expect(time_sheet.reload.updated_by).to eq(user.id.to_s)
      end

      it 'if timesheet date is not less than 2 days in case of Employee' do
        sign_in employee
        FactoryGirl.create(:user_project,
          user: employee,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: employee,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10",
          to_time: "#{Date.today - 1} 11:30"
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 9:00",
              to_time: "#{Date.today - 1} 11:15",
              id: time_sheet.id
            }
          },
          id:user.id
        }
        post :update_timesheet, user_id: employee.id,
          user: params,
          time_sheet_date: Date.today - 1
        expect(time_sheet.reload.from_time.to_s).
          to eq("#{Date.today - 1} - 09:00 AM")
        expect(time_sheet.reload.to_time.to_s).
          to eq("#{Date.today - 1} - 11:15 AM")
      end

      it 'if timesheet date is less than 2 days in case of Admin' do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 4,
          from_time: "#{Date.today - 4} 10",
          to_time: "#{Date.today - 4} 11:30"
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 5,
              from_time: "#{Date.today - 5} 9:00",
              to_time: "#{Date.today - 5} 11:15",
              id: time_sheet.id
            }
          },
          id:user.id
        }
        post :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 4
        expect(time_sheet.reload.from_time.to_s).
          to eq("#{Date.today - 5} - 09:00 AM")
        expect(time_sheet.reload.to_time.to_s).
          to eq("#{Date.today - 5} - 11:15 AM")
      end

      it 'if timesheet date is greter than 7 days' do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 15
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10",
          to_time: "#{Date.today - 1} 11:30",
          created_by: user.id
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 12,
              from_time: "#{Date.today - 12} 10:00",
              to_time: "#{Date.today - 12} 11:00",
              description: 'testing API',
              id: time_sheet.id
            }
          },
          id: user.id
        }
        post :update_timesheet, user_id: user.id,
                                user: params,
                                time_sheet_date: Date.today - 1
        expect(time_sheet.reload.date).to eq(Date.today - 12)
        expect(flash[:notice]).to eq('Timesheet Updated Successfully')
      end
    end

    context 'should not update timesheet' do
      it "if 'description' is not present" do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10",
          to_time: "#{Date.today - 1} 11:30",
          description: 'Worked on test cases'
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 09:00",
              to_time: "#{Date.today - 1} 11:15",
              description: '',
              id: time_sheet.id
            }
          },
          id:user.id
        }
        post :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        assigns(:time_sheets)[0].errors.full_messages ==
          ["Description can't be blank"]
        expect(time_sheet.reload.description).to eq('Worked on test cases')
        should render_template(:edit_timesheet)
      end

      it "if 'from time' is not present" do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10",
          to_time: "#{Date.today - 1} 11:30"
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: '',
              to_time: "#{Date.today - 1} 11:15",
              duration: nil,
              id: time_sheet.id
            }
          },
          id:user.id
        }
        post :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        assigns(:time_sheets)[0].errors.full_messages ==
          ["From time Invalid time format. Format should be HH:MM"]
        expect(time_sheet.reload.from_time).
          to eq(Time.parse("#{Date.today - 1} 10"))
        should render_template(:edit_timesheet)
      end

      it "if 'to time' is not present" do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10",
          to_time: "#{Date.today - 1} 11:30"
        )
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 09:00",
              to_time: '',
              duration: nil,
              id: time_sheet.id
            }
          },
          id:user.id
        }
        post :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        assigns(:time_sheets)[0].errors.full_messages ==
          ["To time Invalid time format. Format should be HH:MM"]
        expect(time_sheet.reload.to_time).
          to eq(Time.parse("#{Date.today - 1} 11:30"))
        should render_template(:edit_timesheet)
      end

      it 'if duration, from_time and to_time is absent' do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10:00",
          to_time: "#{Date.today - 1} 11:30",
          description: 'testing test-suite'
        )
        from_time = time_sheet.from_time
        to_time = time_sheet.to_time
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: nil,
              to_time: nil,
              duration: nil,
              description: 'testing API and call with client',
              id: time_sheet.id
            }
          },
          id:user.id
        }
        put :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        expect(time_sheet.reload.from_time).
          to eq(from_time)
        expect(time_sheet.reload.to_time).
          to eq(to_time)
        expect(time_sheet.reload.description).
          to eq('testing test-suite')
        expect(time_sheet.reload.duration).
          to eq(90)
        should render_template(:edit_timesheet)
      end

      it 'if duration and one of from_time and to_time is absent' do
        sign_in user
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10:00",
          to_time: "#{Date.today - 1} 11:30",
          description: 'testing test-suite'
        )
        from_time = time_sheet.from_time
        to_time = time_sheet.to_time
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 11:00",
              to_time: nil,
              duration: nil,
              description: 'testing API and call with client',
              id: time_sheet.id
            }
          },
          id:user.id
        }
        put :update_timesheet, user_id: user.id,
          user: params,
          time_sheet_date: Date.today - 1
        expect(time_sheet.reload.from_time).
          to eq(from_time)
        expect(time_sheet.reload.to_time).
          to eq(to_time)
        expect(time_sheet.reload.description).
          to eq('testing test-suite')
        expect(time_sheet.reload.duration).
          to eq(90)
        should render_template(:edit_timesheet)
      end

      it "if timesheet date is less than #{ TimeSheet::DAYS_FOR_UPDATE } days in case of Employee" do
        sign_in employee
        FactoryGirl.create(:user_project,
          user: employee,
          project: project,
          start_date: Date.today - 10
        )
        time_sheet = FactoryGirl.build(:time_sheet,
          user: employee,
          project: project,
          date: Date.today - 9,
          from_time: "#{Date.today - 9} 10",
          to_time: "#{Date.today - 9} 11:30"
        )
        time_sheet.save(:validate => false)
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 9,
              from_time: "#{Date.today - 9} 11:00",
              to_time: "#{Date.today - 9} 10:00",
              description: 'testing API and call with client',
              id: time_sheet.id
            }
          },
          id: user.id
        }
        post :update_timesheet, user_id: employee.id,
                                user: params,
                                time_sheet_date: Date.today - 9
        expect(time_sheet.reload.from_time).
          to eq(Time.parse("#{Date.today - 9} 10"))
        expect(time_sheet.reload.to_time).
          to eq(Time.parse("#{Date.today - 9} 11:30"))
        expect(flash[:error]).to eq(
          "Not allowed to edit timesheet for this date. You can edit timesheet for past #{TimeSheet::DAYS_FOR_UPDATE} days."
        )
        should render_template(:edit_timesheet)
      end

      it "if one user trying to update other user's timesheet" do
        user1 = FactoryGirl.create(:employee)
        timesheet = FactoryGirl.create(:time_sheet, project: project, user: employee)
        sign_in user1
        params = {
          time_sheets_attributes: {
            "0" => {
              project_id: project.id,
              date: Date.today - 9,
              from_time: "#{Date.today - 9} 10:00",
              to_time: "#{Date.today - 9} 11:00",
              description: 'testing API and call with client',
              id: timesheet.id
            }
          }
        }
        post :update_timesheet, user_id: user1.id,
                                user: params,
                                time_sheet_date: timesheet.date
        expect(response).to have_http_status(302)
        expect(flash[:error]).to eq("Invalid access")
        should redirect_to(edit_time_sheets_path)
      end
    end
  end

  # context 'Export project report' do
  #   let!(:user) { FactoryGirl.create(:admin) }
  #   let!(:user_one) { FactoryGirl.create(:user) }
  #   let!(:user_two) { FactoryGirl.create(:user) }
  #   let!(:project) {FactoryGirl.create(:project)}

  #   it 'Should give the project report' do
  #     user_one.public_profile.first_name = 'Aaaaa'
  #     user_one.save
  #     FactoryGirl.create(:user_project,
  #       user: user_one,
  #       project: project,
  #       start_date: Date.today - 20
  #     )
  #     FactoryGirl.create(:user_project,
  #       user: user_two,
  #       project: project,
  #       start_date: Date.today - 20
  #     )
  #     FactoryGirl.create(:time_sheet,
  #       user: user_one,
  #       project: project,
  #       date: Date.today - 2,
  #       from_time: "#{Date.today - 2} 10",
  #       to_time: "#{Date.today - 2} 11",
  #       description: 'Test api'
  #     )
  #     FactoryGirl.create(:time_sheet,
  #       user: user_one,
  #       project: project,
  #       date: Date.today - 2,
  #       from_time: "#{Date.today - 2} 12",
  #       to_time: "#{Date.today - 2} 13",
  #       description: 'call with client'
  #     )
  #     FactoryGirl.create(:time_sheet,
  #       user: user_two,
  #       project: project,
  #       date: Date.today - 2,
  #       from_time: "#{Date.today - 2} 10",
  #       to_time: "#{Date.today - 2} 11",
  #       description: 'test data'
  #     )
  #     from_date = Date.today - 20
  #     to_date = Date.today
  #     sign_in user_one
  #     get :export_project_report, format: 'xlsx',
  #       from_date: from_date,
  #       to_date: to_date,
  #       project_id: project.id
  #     expect(response.body).to eq("Employee name,Date(dd/mm/yyyy),No of hours,Details\n#{user_one.name},#{(Date.today - 2).strftime('%d-%m-%Y')},2,\"Test api\ncall with client\"\n#{user_two.name},#{(Date.today - 2).strftime('%d-%m-%Y')},1,test data\n")
  #   end
  # end

  context 'Add timesheet' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:user_project) { FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: Date.today - 10
      )
    }

    it 'Should add timesheet if from_time and to_time is present' do
      params = {
        time_sheets_attributes: {
          "0" => {
            project_id: "#{project.id}", 
            date: "#{Date.today - 1}",
            from_time: "#{Date.today - 1} 10:00", 
            to_time: "#{Date.today - 1} 11:00",
            duration: nil,
            description: "testing API and call with client"
          }
        },
        user_id: user.id,
        from_date: Date.today - 20,
        to_date: Date.today
      }
      sign_in user
      post :add_time_sheet, user_id: user.id, user: params
      expect(flash[:notice]).to be_present
      expect(user.reload.time_sheets[0].user_id).to eq(user.id)
      expect(user.time_sheets[0].project_id).to eq(project.id)
      expect(user.time_sheets[0].created_by).to eq(user.id.to_s)
    end

    it 'Should add timesheet if duration is present' do
      params = {
        time_sheets_attributes: {
          "0" => {
            project_id: "#{project.id}",
            date: "#{Date.today - 1}",
            from_time: nil,
            to_time: nil,
            duration: 60,
            description: "testing API and call with client"
          }
        },
        user_id: user.id,
        from_date: Date.today - 20,
        to_date: Date.today
      }
      sign_in user
      post :add_time_sheet, user_id: user.id, user: params
      expect(flash[:notice]).to be_present
      expect(user.reload.time_sheets[0].user_id).to eq(user.id)
      expect(user.time_sheets[0].project_id).to eq(project.id)
      expect(user.time_sheets[0].created_by).to eq(user.id.to_s)
    end

    it 'Should not add timesheet if only from_time or to_time is present' do
      params = {
        time_sheets_attributes: {
          "0" => {
            project_id: "#{project.id}",
            date: "#{Date.today - 1}",
            from_time: "#{Date.today - 1} 10:00",
            to_time: nil,
            duration: nil,
            description: "testing API and call with client"
          }
        },
        user_id: user.id,
        from_date: Date.today - 20,
        to_date: Date.today
      }
      sign_in user
      post :add_time_sheet, user_id: user.id, user: params
      assigns(:time_sheets)[0].errors.full_messages ==
        ["To time can't be blank"]
      expect(TimeSheet.count).to eq(0)
      should render_template(:new)
    end

    it 'Should not add timesheet because validation failure' do
      params = { 
        time_sheets_attributes: {
          "0" => {
            project_id: "#{project.id}", 
            date: "#{Date.today - 1}",
            from_time: "#{Date.today - 1} 10:00", 
            to_time: "#{Date.today - 1} 9:00",
            description: "testing API and call with client"
          }
        },
        user_id: user.id,
        from_date: Date.today - 20,
        to_date: Date.today
      }
      sign_in user
      post :add_time_sheet, user_id: user.id, user: params
      assigns(:time_sheets)[0].errors.full_messages ==
        ["From time From time must be less than to time"]
      expect(TimeSheet.count).to eq(0)
      should render_template(:new)
    end

    it 'should add only valid timesheets' do
      sign_in user
      params = {
        user: {
          time_sheets_attributes: {
            '0' => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 10:00",
              to_time: "#{Date.today - 1} 11:00",
              description: "testing API and call with client"
            },
            '1' => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 11:30",
              to_time: "#{Date.today - 1} 12:00",
              description: "testing API and call with client"
            },
            '2' => {
              project_id: project.id,
              date: Date.today - 1,
              from_time: "#{Date.today - 1} 12:30",
              to_time: "#{Date.today - 1} 12:00",
              description: "testing API and call with client"
            }
          },
          user_id: user.id,
          from_date: Date.today - 20,
          to_date: Date.today
        },
        user_id: user.id
      }
      post :add_time_sheet, params
      expect(response).to have_http_status(200)
      expect(flash[:notice]).to eq("2 timesheets created successfully")
      should render_template(:new)
    end
  end
end
