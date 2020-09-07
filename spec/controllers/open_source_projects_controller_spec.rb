require 'spec_helper'

describe OpenSourceProjectsController do

  before(:each) do
   @admin = FactoryGirl.create(:admin)
   sign_in @admin
  end

  describe "GET index" do
    it "should list all open_source_projects" do
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

    it "should create new OpenSourceProject record" do
      get :new
      assigns(:open_source_project).new_record? == true
    end
  end

  describe "GET create" do
    it "should create new OpenSourceProject" do
      post :create, { open_source_project: FactoryGirl.attributes_for(:open_source_project) }
      expect(flash[:success]).to eq("Open Source Project created Successfully")
      should redirect_to open_source_projects_path
    end

    it "should not save open_source_project without name" do
      post :create, {
        open_source_project: FactoryGirl.attributes_for(:open_source_project).merge(name: '')
      }
      assigns(:open_source_project).errors.full_messages == ["Name can't be blank"]
      should render_template(:new)
    end
  end

  describe "GET edit" do
    it "returns http success" do
      open_source_project = FactoryGirl.create(:open_source_project)
      get :edit, id: open_source_project.id
      expect(response).to be_success
    end
  end

  describe "PATCH update" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:open_source_project) { FactoryGirl.create(:open_source_project) }

    it 'Should update user ids and open_source_project_ids' do
      user_id = []
      user_id << user.id
      patch :update, id: open_source_project.id, open_source_project: { user_ids: user_id }
      expect(open_source_project.reload.user_ids.include?(user.id)).to eq(true)
      expect(user.reload.open_source_project_ids.include?(open_source_project.id)).to eq(true)
    end
  end

  describe "GET show" do
    it "should find one Open Source Project record" do
      open_source_project = FactoryGirl.create(:open_source_project)
      get :show, id: open_source_project.id
      expect(assigns(:open_source_project)).to eq(open_source_project)
    end

    it "Should equal to team members" do
      user = FactoryGirl.create(:user)
      open_source_project = FactoryGirl.create(:open_source_project, users: [user])
      get :show, id: open_source_project.id
      expect(response).to be_success
      expect(assigns(:team_members)).to eq(open_source_project.users)
    end
  end
end
