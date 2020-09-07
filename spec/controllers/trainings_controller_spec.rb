require 'spec_helper'

describe TrainingsController do

  before(:each) do
   @admin = FactoryGirl.create(:admin)
   sign_in @admin
  end

  describe "GET index" do
    it "should list all trainings" do
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

    it "should create new Training record" do
      get :new
      assigns(:training).new_record? == true
    end
  end

  describe "GET create" do
    it "should create new Training" do
      post :create, { training: FactoryGirl.attributes_for(:training) }
      expect(flash[:success]).to eq("Training Record created Successfully")
      should redirect_to trainings_path
    end

    it "should not save training without subject" do
      post :create, {
        training: FactoryGirl.attributes_for(:training).merge(subject: '')
      }
      expect(assigns(:training).errors.full_messages).to eq(["Subject can't be blank"])
      should render_template(:new)
    end

    it "should not save training without objectives" do
      post :create, {
        training: FactoryGirl.attributes_for(:training).merge(objectives: '')
      }
      expect(assigns(:training).errors.full_messages).to eq(["Objectives can't be blank"])
      should render_template(:new)
    end

    it "should not save training if chapter is invalid" do
      chapters_attributes = {
        '0' => FactoryGirl.attributes_for(:chapter, chapter_number: nil)
      }
      post :create, {
        training: FactoryGirl.attributes_for(:training).merge(chapters_attributes: chapters_attributes)
      }
      expect(assigns(:training).errors.full_messages).to eq(["Chapters is invalid"])
      should render_template(:new)
    end
  end

  describe "GET edit" do
    it "returns http success" do
      training = FactoryGirl.create(:training)
      get :edit, id: training.id
      expect(response).to be_success
    end
  end

  describe "PATCH update" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:training) { FactoryGirl.create(:training) }

    it 'Should update training record' do
      user_id = []
      user_id << user.id
      patch :update, id: training.id, training: { trainer_ids: user_id }
      expect(training.reload.trainer_ids.include?(user.id)).to eq(true)
      expect(user.reload.training_ids.include?(training.id)).to eq(true)
    end

    it 'Should update chapter record' do
      user_id = []
      user_id << user.id
      params = {
        id: training.id,
        training: {
          chapters_attributes: {
            '0' => FactoryGirl.attributes_for(:chapter).merge(trainer_ids: user_id)
          }
        }
      }
      patch :update, params
      expect(training.reload.chapters[0].trainer_ids.include?(user.id)).to eq(true)
    end

    it 'Should fail to update training record if record is invalid' do
      user_id = []
      user_id << user.id
      patch :update, id: training.id, training: { duration: nil }
      expect(flash[:error]).to eq("Training record updation failed")
      should render_template('edit')
    end

    it 'Should fail to add/update chapter record if record is invalid' do
      user_id = []
      user_id << user.id
      params = {
        id: training.id,
        training: {
          chapters_attributes: {
            '0' => FactoryGirl.attributes_for(:chapter, chapter_number: nil)
          }
        }
      }
      patch :update, params
      expect(training.reload.chapters.count).to eq(0)
    end
  end

  describe "GET show" do
    it "should find one Training record" do
      training = FactoryGirl.create(:training)
      get :show, id: training.id
      expect(assigns(:training)).to eq(training)
    end
  end
end
