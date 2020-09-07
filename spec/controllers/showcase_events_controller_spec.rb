require 'spec_helper'

describe ShowcaseEventsController do

  before(:each) do
   @admin = FactoryGirl.create(:admin)
   sign_in @admin
  end

  describe "GET index" do
    it "should list all Events" do
      get :index
      should respond_with(:success)
      should render_template(:index)
    end
  end

  describe "GET new" do
    it "should respond with success" do
      get :new
      should respond_with(:success)
      should render_template(:new)
    end

    it "should create new Event record" do
      get :new
      assigns(:showcase_event).new_record? == true
    end
  end

  describe "GET create" do
    it "should create new Event" do
      post :create, { showcase_event: FactoryGirl.attributes_for(:showcase_event) }
      expect(flash[:success]).to eq("Event created Successfully")
      should redirect_to showcase_events_path
    end

    it "should not save showcase_event without name" do
      post :create, {
        showcase_event: FactoryGirl.attributes_for(:showcase_event).merge(name: '')
      }
      assigns(:showcase_event).errors.full_messages == ["Name can't be blank"]
      should render_template(:new)
    end
  end

  describe "GET edit" do
    it "returns http success" do
      showcase_event = FactoryGirl.create(:showcase_event)
      get :edit, id: showcase_event.id
      expect(response).to be_success
    end
  end

  describe "PATCH update" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:showcase_event) { FactoryGirl.create(:showcase_event) }

    it 'should update event topics' do
      showcase_event_application = FactoryGirl.attributes_for(:showcase_event_application)
      params = {
        id: showcase_event.id,
        showcase_event: {
          showcase_event_applications_attributes: {
            '0' => showcase_event_application
          }
        }
      }
      patch :update, params
      expect(showcase_event.reload.showcase_event_applications[0].name).to eq(showcase_event_application[:name])
    end

    it 'should update event team details' do
      users = FactoryGirl.create_list(:user, 3)
      showcase_event_application = FactoryGirl.create(:showcase_event_application, showcase_event: showcase_event)
      showcase_event_team = FactoryGirl.attributes_for(:showcase_event_team, showcase_event_application: showcase_event_application, member_ids: users.collect(&:id))
      params = {
        id: showcase_event.id,
        showcase_event: {
          showcase_event_teams_attributes: {
            '0' => showcase_event_team
          }
        }
      }
      patch :update, params
      expect(showcase_event.reload.showcase_event_teams[0].name).to eq(showcase_event_team[:name])
    end

    it 'should fail to update event topics if topic details is invalid' do
      showcase_event_application = FactoryGirl.attributes_for(:showcase_event_application, name: nil)
      params = {
        id: showcase_event.id,
        showcase_event: {
          showcase_event_applications_attributes: {
            '0' => showcase_event_application
          }
        }
      }
      patch :update, params
      expect(flash[:error]).to eq('Event updation failed')
      expect(showcase_event.reload.showcase_event_applications.count).to eq(0)
      should render_template('edit')
    end

    it 'should fail to update event team details if team details is invalid' do
      users = FactoryGirl.create_list(:user, 3)
      showcase_event_application = FactoryGirl.create(:showcase_event_application, showcase_event: showcase_event)
      showcase_event_team = FactoryGirl.attributes_for(:showcase_event_team, name: nil, showcase_event_application: showcase_event_application, member_ids: users.collect(&:id))
      params = {
        id: showcase_event.id,
        showcase_event: {
          showcase_event_teams_attributes: {
            '0' => showcase_event_team
          }
        }
      }
      patch :update, params
      expect(flash[:error]).to eq('Event updation failed')
      expect(showcase_event.reload.showcase_event_teams.count).to eq(0)
      should render_template('edit')
    end
  end

  describe "GET show" do
    it "should find one Open Source Project record" do
      showcase_event = FactoryGirl.create(:showcase_event)
      get :show, id: showcase_event.id
      expect(assigns(:showcase_event)).to eq(showcase_event)
    end

    it "should be equal to topics" do
      user = FactoryGirl.create(:user)
      showcase_event = FactoryGirl.create(:showcase_event)
      showcase_event_application1 = FactoryGirl.create(:showcase_event_application, showcase_event: showcase_event)
      showcase_event_application2 = FactoryGirl.create(:showcase_event_application, showcase_event: showcase_event)
      get :show, id: showcase_event.id
      expect(response).to be_success
      expect(assigns(:showcase_event_applications)).to eq([showcase_event_application1, showcase_event_application2])
    end
  end
end
