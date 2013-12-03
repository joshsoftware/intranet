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

end
