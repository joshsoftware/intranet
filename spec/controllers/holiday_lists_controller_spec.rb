require 'rails_helper'

RSpec.describe HolidayListsController, type: :controller do
  context '#create' do
    it 'create holiday' do
      date = Date.today
      date = date - 2.days if date.saturday? || date.sunday?
      params = FactoryGirl.attributes_for(:holiday, holiday_date: date)
      post :create, {:holiday_list => params}
      expect(flash[:success]).to eq('Holiday Created Successfully')
    end
  end

  context '#index' do 
    it 'show list of holidays' do
      get :index
      expect(response).to have_http_status(200)
      expect(response).to render_template :index
    end
  end

  context '#edit' do
    let!(:holiday) { FactoryGirl.create(:holiday) }
    it 'should success and render to edit page' do
     get :edit, id: holiday.id
     expect(response).to have_http_status(200)
     expect(response).to render_template :edit
    end
  end

  context '#new' do
    it 'create new holiday' do
      get :new
      expect(response).to have_http_status(200)
      expect(response).to render_template :new
    end
  end

  context '#destroy' do
    it 'delete hoilday' do
      holiday = FactoryGirl.create(:holiday)
      delete :destroy, id: holiday.id
      expect(HolidayList.count).to eq(0)
      expect(response).to redirect_to(holiday_lists_path)
    end
  end

  context '#update' do
    let!(:holiday) { FactoryGirl.create(:holiday) } 
    it 'update holiday' do
      params  = {
        holiday_date: '05/09/2019',
        reason: 'test'
      }
      put :update, id: holiday.id, holiday_list: params
      expect(flash[:success]).to eq('Holiday Updated Successfully')
    end
  end

  context '#holiday_list' do
    before do
      FactoryGirl.create(:holiday)
      @user = FactoryGirl.create(:user)
      sign_in @user
    end

    it 'render holiday list' do
      get :holiday_list
      expect(response).to have_http_status(:success)
    end
  end
end
