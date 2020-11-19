require 'rails_helper'

RSpec.describe FutureTeamsController, type: :controller do

  before(:each) do
   @admin = FactoryGirl.create(:admin)
   sign_in @admin
  end

  describe "GET #new" do
    it "should respond with success" do
      get :new
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end

    it "should create new future team requirement record" do
      get :new
      assigns(:future_team).new_record? == true
    end
  end

  describe "GET #index" do
    it "should list all future team requirements" do
      get :index
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #create" do
    it "should create new future team requirement" do
      post :create, { future_team: FactoryGirl.attributes_for(:future_team) }
      expect(flash[:success]).to eq("Future Team Requirement created successfully!!!")
      expect(response).to redirect_to(future_teams_path)
    end
  end

  describe "#show" do
    it "should find future team requirement record" do
      future_team = FactoryGirl.create(:future_team)
      get :show, id: future_team.id
      expect(assigns(:future_team)).to eq(future_team)
    end
  end

  describe "GET #edit" do
    it "should render edit template" do
      future_team = FactoryGirl.create(:future_team)
      get :edit, {id: future_team.id}
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #close" do
    it "should render close template" do
      future_team = FactoryGirl.create(:future_team)
      get :close, {id: future_team.id}
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #update' do
    before(:each) do
      @future_team = FactoryGirl.create(:future_team)
    end

    it 'should update attributes' do
      skills = ["Python"]
      post :update, {
        id: @future_team.id,
        future_team: { skills: skills }
      }
      expect(@future_team.reload.skills).to eq(skills)
    end
  end

  context 'DELETE #destroy' do
    it 'should delete future team requirement' do
      future_team = FactoryGirl.create(:future_team)
      delete :destroy, id: future_team.id
      expect(FutureTeam.count).to eq(0)
      expect(response).to redirect_to(future_teams_path)
    end
  end
end
