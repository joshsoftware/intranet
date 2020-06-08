require 'rails_helper'

RSpec.describe EmployeeProjectTransfersController, type: :controller do
  before(:each) do
    @admin = FactoryGirl.create(:admin)
    @candidate = FactoryGirl.create(:user, status: 'approved')
    @super_admin = FactoryGirl.create(:super_admin)
    sign_in @admin
    @project1 = FactoryGirl.create(:project)
    @project2 = FactoryGirl.create(:project)
    user_project = FactoryGirl.create(:user_project, user:@candidate, project: @project1)
    @request1 = FactoryGirl.create(:employee_project_transfer, requested_by: @admin.id, request_for: @candidate.id,
                                  from_project: @project1.id.to_s, to_project: @project2.id.to_s
                                )
  end

  context 'GET index' do
    it "should list all employee project transfer requests" do
      get :index
      should respond_with(:success)
      should render_template(:index)
    end
  end

  context 'GET new' do
    it "should respond with success" do
      get :new
      should respond_with(:success)
      should render_template(:new)
    end

    it "should create new employee project transfer record" do
      get :new
      assigns(:employee_project_transfer).new_record? == true
    end
  end

  describe "POST create" do
    it "should create new employee project transfer request" do
      post :create, { employee_project_transfer: @request1.attributes }
      expect(flash[:success]).to eq("Employee Project Transfer request created Succesfully")
      should redirect_to employee_project_transfers_path
    end
  end

  describe "GET edit" do
    it 'should success and render to edit page' do
      get :edit, id: @request1.id
      expect(response).to have_http_status(200)
      expect(response).to render_template :edit
    end
  end

  context 'PUT update' do
    it 'should update employee project transfer request' do
      params  = {
        start_date: Date.today + 10,
        reason: 'test'
       }
      put :update, id: @request1.id, employee_project_transfer: params
      expect(flash[:success]).to eq("Employee Project Transfer request updated Succesfully")
    end
  end

  context 'GET process_request' do
    it 'should approve request' do
      sign_out @admin
      sign_in @super_admin
      get :process_request, {
        id: @request1.id,
        perform_action: 'approve'
      }
      @request1.reload
      expect(@request1.status).to eq(APPROVED)
    end

    it 'should reject request' do
      sign_out @admin
      sign_in @super_admin
      get :process_request, {
        id: @request1.id,
        perform_action: 'reject'
      }
      @request1.reload
      expect(@request1.status).to eq(REJECTED)
    end
  end
end
