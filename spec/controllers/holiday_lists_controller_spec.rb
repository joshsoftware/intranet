require 'rails_helper'

RSpec.describe HolidayListsController, type: :controller do

  describe "#index" do
    it "should list all holidays" do
      get :index
      expect(response).to render_template(:index)
      expect(response).to have_http_status(200)
    end
  end

  describe "#new" do
    it "should respond with success" do
      get :new
      expect(response).to have_http_status(200)
      expect(response).to render_template(:_add_holiday)
    end

    it "should create new holiday record" do
      get :new
      assigns(:holiday).new_record? == true
    end
  end

  describe "#create" do
    it "should create new holiday" do
      post :create, { holiday_list: FactoryGirl.attributes_for(:holiday) }
      expect(flash[:notice]).to eq "Holiday Added Succesfully"
    end

    it "should flash error on invalid record" do
      params = { holiday_list: FactoryGirl.attributes_for(:holiday) }
      params[:holiday_list][:holiday_date] = nil
      post :create, params
      expect(flash[:error]).to eq "Same Holiday cannot be add Or Date and Reason for Holiday is compulsory"
    end

    it "should redirect to same page after adding holiday" do
      post :create, { holiday_list: FactoryGirl.attributes_for(:holiday) }
      expect(response).to redirect_to(new_holiday_list_path)
    end

    it "should redirect to same page if record is invalid" do
      params = { holiday_list: FactoryGirl.attributes_for(:holiday) }
      params[:holiday_list][:holiday_date] = nil
      post :create, params
      expect(response).to redirect_to(new_holiday_list_path)
    end
  end

  describe '#destroy' do
    it 'should delete holiday record' do
      holiday = FactoryGirl.create(:holiday)
      delete :destroy, id: holiday.id
      expect(HolidayList.count).to eq(0)
      expect(response).to redirect_to(holiday_lists_path)
    end
  end
end
