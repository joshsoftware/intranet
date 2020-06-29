require 'spec_helper'
require './spec/support/vendor_csv_generator'

RSpec.configure do |c|
  c.include VendorCsvGenerator
end

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
    it 'redirect to vendors_path if record is valid' do
      params = {
        vendor: FactoryGirl.attributes_for(:vendor)
      }
      post :create, params
      expect(response).to redirect_to(vendors_path)
    end

    it 'should render new if record is invalid' do
      params = {
        vendor: FactoryGirl.attributes_for(:vendor, category: nil)
      }
      post :create, params
      expect(Vendor.count).to eq(0)
      should render_template(:new)
    end
  end

  describe "DELETE 'destroy'" do
    it 'return http success' do
      vendor = FactoryGirl.create(:vendor)
      delete :destroy, { id: vendor.id }
      expect(flash[:notice]).to eq('Vendor deleted Successfully')
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

  describe "POST 'import_vendor'" do
    it 'should import data from csv if csv is valid' do
      vendor = FactoryGirl.build(:vendor)
      file = generate_valid_csv(vendor)
      path = file.path
      params = { "csv_file" => Rack::Test::UploadedFile.new(path, 'application/csv', true) }
      post :import_vendors, params
      expect(response).to have_http_status(302)
      expect(Vendor.count).to eq(1)
      expect(Vendor.last.contact_persons.count).to eq(1)
      expect(flash[:notice]).to eq("Vendors added successfully from CSV")
    end

    it "should update contact_person's data if contact_person already exist" do
      vendor = FactoryGirl.create(:vendor)
      contact_person = FactoryGirl.create(:contact_person, vendor: vendor)
      file = generate_valid_csv(vendor, email = 'changed@testmail.com', is_change = true)
      path = file.path
      params = { "csv_file" => Rack::Test::UploadedFile.new(path, 'application/csv', true) }
      post :import_vendors, params
      expect(response).to have_http_status(302)
      expect(Vendor.count).to eq(1)
      expect(vendor.contact_persons.count).to eq(1)
      expect(vendor.contact_persons.last.email).to eq('changed@testmail.com')
      expect(flash[:notice]).to eq("Vendors added successfully from CSV")
    end

    it "should not update contact_person's data if csv is invalid" do
      vendor = FactoryGirl.create(:vendor)
      contact_person = FactoryGirl.create(:contact_person, vendor: vendor)
      file = generate_invalid_csv(vendor)
      path = file.path
      params = { "csv_file" => Rack::Test::UploadedFile.new(path, 'application/csv', true) }
      post :import_vendors, params
      expect(response).to have_http_status(302)
      expect(Vendor.count).to eq(1)
      expect(Vendor.last.contact_persons.count).to eq(1)
      expect(flash[:error]).to eq("Error in csv file")
      expect(Vendor.last.contact_persons.last.email).not_to eq('test12@testmail.com')
    end
  end
end
