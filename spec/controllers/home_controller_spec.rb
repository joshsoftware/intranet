require 'spec_helper'

describe HomeController do
  context '#index' do
    it 'should render index page' do
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template :index
    end
  end

  context '#store_url' do
    it 'should store url' do
     get :store_url
     expect(response).to have_http_status(302)
    end
  end
end
