require 'spec_helper'

describe ProjectsController do
  
  before(:each) do
   @admin = FactoryGirl.create(:user, role: 'Admin')
   sign_in @admin
  end
  describe "GET index" do
    it "should list all projects" do
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

    it "should create new project record" do
      get :new 
      assigns(:project).new_record? == true
    end
  end

  describe "GET create" do
    it "should create new project" do
      post :create, {project: {name: "Intranet", code_climate_id: "12345", code_climate_snippet: "Intranet"}}
      flash.notice.should eql("Project created Succesfully")
      should redirect_to projects_path
    end

    it "should not save project without name" do
      project = FactoryGirl.build(:project, name: "")
      post :create, {project: {name: "", code_climate_id: "12345", code_climate_snippet: "Intranet"}}
      project.errors.full_messages.should_not equal([])
      should render_template(:new)
    end
  end

  describe "GET show" do
    it "should find one project record" do
      project = FactoryGirl.create(:project)
      get :show, id: project.id
      expect(assigns(:project)).to eq(project)
    end
  end
end
