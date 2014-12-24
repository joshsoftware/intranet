require 'spec_helper'

describe AttachmentsController do

  before(:each) do
    @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin')
    sign_in @admin
  end

  describe '#index' do
    it 'renders index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  context "#update" do

    before(:each) do
      @attachment = FactoryGirl.create(:attachment, is_visible_to_all: true)
    end

    it 'will make is_visible false' do
      post :update, {id: @attachment.id, "attachment" => {is_visible_to_all: false}}
      expect(@attachment.reload.is_visible_to_all).to eq(false)
    end

    it 'will make is_visible true' do
      post :update, {id: @attachment.id, "attachment" => {is_visible_to_all: true}}
      expect(@attachment.reload.is_visible_to_all).to eq(true)
    end
  end
end
