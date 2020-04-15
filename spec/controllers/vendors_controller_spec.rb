require 'spec_helper'

describe VendorsController do
  
  before(:each) do
    admin = FactoryGirl.create(:user, role: 'Admin')
    sign_in admin
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'redirect to vendors_path' do
      params = {
        vendor: FactoryGirl.attributes_for(:vendor)
      }
      post :create, params
      expect(response).to redirect_to(vendors_path)
    end
  end

  describe "DELETE 'destroy'" do
    it 'return http success' do
      vendor = FactoryGirl.create(:vendor)
      delete :destroy, { id: vendor.id }
      expect(flash[:notice]).to eq('Vendor deleted Succesfully')
      expect(response).to redirect_to(vendors_path)
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      expect(response).to be_success
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      vendor = Vendor.create(company: 'Vendor', category: "Hardware")
      get 'edit', id: vendor.id
      expect(response).to be_success
    end
  end

  describe "PATCH 'update'" do
    it "returns http success" do
      vendor = Vendor.create(company: 'MS', category: "Hardware")
      patch :update, id: vendor.id, vendor: { id: vendor.id, category: "Hardware and ISP" }
      expect(response).to redirect_to(vendors_path)
    end
  end

end
