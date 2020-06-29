require 'spec_helper'

RSpec.describe CompaniesController, type: :controller do
  before(:each) do
    @admin = FactoryGirl.create(:admin)
    sign_in @admin
  end

  describe "#index" do
    it "should list all companies" do
      get :index
      expect(response).to render_template(:index)
      expect(response).to have_http_status(200)
    end
  end

  describe "#new" do
    it "should respond with success" do
      get :new
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
    end

    it "should create new project record" do
      get :new
      assigns(:company).new_record? == true
    end

    it "should build address record" do
      get :new
      assigns(:company).addresses.present? == true
    end
  end

  describe "#create" do
    it "should create new project" do
      post :create, { company: FactoryGirl.attributes_for(:company) }
      expect(flash[:success]).to eq "Company created Successfully"
    end

    it "should render new on invalid record" do
      params = { company: FactoryGirl.attributes_for(:company) }
      params[:company][:name] = nil
      post :create, params
      expect(response).to render_template(:new)
    end
  end

  describe "#edit" do
    let(:company) { FactoryGirl.create(:company) }

    it "should respond with success" do
      get :edit, id: company.id
      expect(response).to render_template(:edit)
      expect(response).to have_http_status(200)
    end

    it "should return company record" do
      get :edit, id: company.id
      expect(assigns(:company).new_record?).to be_falsy
    end

    it "should build address record" do
      get :edit, id: company.id
      address = assigns(:company).addresses.first
      expect(address.new_record?).to be_truthy
    end
  end

  describe "#show" do
    it "should find company record" do
      company = FactoryGirl.create(:company)
      get :show, id: company.id
      expect(assigns(:company)).to eq(company)
    end
  end

  describe '#update' do
    it "should update company record" do
      company = FactoryGirl.create(:company)
      updated_attributes = FactoryGirl.attributes_for(:company)
      patch :update, { company: updated_attributes, id: company.id }
      expect(company.reload.name).to eq(updated_attributes[:name])
    end

    it "should accept nested attributes for contact" do
      company = FactoryGirl.create(:company)
      params = {
        company: {
          contact_persons_attributes: {
            '0' => FactoryGirl.attributes_for(:contact_person)
          }
        },
        id: company.id
      }
      patch :update, params
      expect(company.reload.contact_persons.count).to eq(1)
    end

    it "should accept nested attributes for addresses" do
      company = FactoryGirl.create(:company)
      params = {
        company: {
          addresses_attributes: {
            '0' => FactoryGirl.attributes_for(:address)
          }
        },
        id: company.id
      }
      patch :update, params
      expect(company.reload.addresses.count).to eq(1)
    end
  end

  describe '#destroy' do
    it 'should delete company record' do
      company = FactoryGirl.create(:company)
      delete :destroy, id: company.id
      expect(Company.count).to eq(0)
      expect(response).to redirect_to(companies_path)
    end
  end
end
