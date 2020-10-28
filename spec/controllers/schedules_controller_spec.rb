require 'spec_helper'

RSpec.describe SchedulesController, :type => :controller do
  before(:each) do
    @request.env['devise.mapping'] = :hr
    FactoryGirl.create(:hr)
    @hr = FactoryGirl.create(:hr)
  end

  context 'GET index' do
    it 'lists all events' do
      sign_in @hr
      get :index
      expect(response).to render_template('index')
    end
  end

  context 'GET edit' do
    it 'shows details of event' do
    	e1 = FactoryGirl.create(:schedule)
      sign_in @hr
      get :edit, { id: e1.id }
      expect(response).to render_template('edit')
    end
  end

  context 'GET new' do
    it 'shows details of event' do
      sign_in @hr
      get :new
      expect(response).to render_template('new')
    end
  end

  context 'DELETE delete' do
    it 'deletes event' do
      e1 = FactoryGirl.create(:schedule)
      @request.env["devise.mapping"] = :user
      sign_in FactoryGirl.create(:user)
      get :destroy, { id: e1.id }
      expect(response).not_to redirect_to schedules_path
    end
  end
end
