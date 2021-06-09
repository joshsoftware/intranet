require 'rails_helper'

RSpec.describe HolidayListsController, type: :controller do
  before(:each) do
    @admin = FactoryGirl.create(:admin)
    sign_in @admin
  end

  context '#create' do
    it 'create holiday' do
      date = Date.today
      date = date - 2.days if date.saturday? || date.sunday?
      params = FactoryGirl.attributes_for(:holiday, holiday_date: date)
      post :create, {holiday_list: params}
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
      @holiday = FactoryGirl.create(:holiday)
    end

    it 'render holiday list' do
      get :holiday_list

      holiday_list = JSON.parse response.body
      expect(response).to have_http_status(:success)
      expect(holiday_list.first['country']).to eq(@holiday.country)
      expect(holiday_list.first['holiday_date']).to eq(@holiday.holiday_date.strftime("%Y-%m-%d"))
      expect(holiday_list.first['holiday_type']).to eq(@holiday.holiday_type)
      expect(holiday_list.first['reason']).to eq(@holiday.reason)
    end

    it 'render holiday list by location and leave type (Optional)' do
      holiday = FactoryGirl.create(:holiday, holiday_type: HolidayList::OPTIONAL, country: COUNTRIES[:usa])
      params = {
        location: COUNTRIES[:usa],
        leave_type: HolidayList::OPTIONAL
      }
      get :holiday_list, params

      holiday_list = JSON.parse response.body
      expect(response).to have_http_status(:success)
      expect(holiday_list.first['country']).to eq('USA')
      expect(holiday_list.first['holiday_date']).to eq(holiday.holiday_date.strftime("%Y-%m-%d"))
      expect(holiday_list.first['holiday_type']).to eq(HolidayList::OPTIONAL)
      expect(holiday_list.first['reason']).to eq(holiday.reason)
    end
  end

  context 'as consultant role' do
    before do
      @consultant = FactoryGirl.create(:consultant)
      sign_in @consultant
    end

    it 'should not allow to view policies' do
      get :index
      expect(response).to have_http_status(200)
      expect(response).to render_template :index
    end
  end
end
