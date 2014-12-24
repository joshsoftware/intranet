require 'spec_helper'
require 'rake'
load File.expand_path("../../../lib/tasks/leave_reminder.rake", __FILE__)
describe LeaveApplicationsController do
  context "Employee, manager and HR" do
    before(:each) do
      @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR') 
      @user = FactoryGirl.create(:user, role: 'Employee')
      sign_in @user
      @leave_application = FactoryGirl.build(:leave_application, user_id: @user.id)
    end

    it "should able to view new leave apply page" do
      get :new, {user_id: @user.id}
      should respond_with(:success)
      should render_template(:new) 
    end

    context "leaves view" do
      before (:each) do
        @user.build_private_profile(FactoryGirl.build(:private_profile).attributes)
        @user.public_profile = FactoryGirl.build(:public_profile)
        @user.save
        @leave_application = FactoryGirl.build(:leave_application, user_id: @user.id)
        post :create, {user_id: @user.id, leave_application: @leave_application.attributes.merge(number_of_days: 2)}
        user2 = FactoryGirl.create(:user, id: "52b28303dd1b36927d000009", email: 'user2@joshsoftware.com', role: 'Employee')  
        user2.build_private_profile(FactoryGirl.build(:private_profile).attributes)
        user2.public_profile = FactoryGirl.build(:public_profile)
        user2.save
        @leave_application = FactoryGirl.build(:leave_application, user_id: user2.id)
        post :create, {user_id: user2.id, leave_application: @leave_application.attributes.merge(number_of_days: 2)}
      end

      it "should show only his leaves if user is not admin" do
        get :view_leave_status
        assigns(:pending_leave).count.should eq(1)
      end

      it "user is admin he could see all leaves" do
        sign_out @user
        sign_in @admin
        get :view_leave_status
        assigns(:pending_leave).count.should eq(2) 
      end
    end

    it "should be able to apply for leave" do
      @user.build_private_profile(FactoryGirl.build(:private_profile).attributes)
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      remaining_leave = @user.employee_detail.available_leaves - @leave_application.number_of_days
      post :create, {user_id: @user.id, leave_application: @leave_application.attributes.merge(number_of_days: 2)}
      LeaveApplication.count.should == 1 
      @user.reload 
      expect(@user.employee_detail.available_leaves).to eq(remaining_leave)
    end

    it "should not able to apply leave if not sufficient leave" do
      @user.build_private_profile(FactoryGirl.build(:private_profile).attributes)
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      @user.employee_detail.update_attribute(:available_leaves, 1)
      post :create, {user_id: @user.id, leave_application: @leave_application.attributes.merge(number_of_days: 9)}
      expect(LeaveApplication.count).to eq 0 
      @user.reload
      expect(@user.employee_detail.available_leaves).to eq(1)
    end
  end

  context "AS HR" do
    before(:each) do
      admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @user = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR', private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      sign_in @user
      @leave_application = FactoryGirl.create(:leave_application, user_id: @user.id) 
    end

    it "should be able to apply leave" do
      get :new, {user_id: @user.id}
      should respond_with(:success)
      should render_template(:new)
    end

    it "should be able to view all leave" do
      get :index
      expect(LeaveApplication.count).to eq(1)
      should respond_with(:success)
      should render_template(:index)
    end

  end

  context "While accepting leaves" do
    before(:each) do
      @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR') 
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      sign_in @admin
    end

    it "Admin as a role should accept leaves " do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Approved" 
    end

    it "Only single mail to employee should get sent on leave appproval" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      get :approve_leave, {id: leave_application.id}
      Sidekiq::Extensions::DelayedMailer.jobs.size.should eq(1)
    end

    it "Admin as a role should to able perform accept(or reject) only one time" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq("Approved")

      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq("Approved")
    end 

    it "should be able to apply leave" do
      get :new, {user_id: @admin.id}
      should respond_with(:success)
      should render_template(:new)
    end

    it "should be able to view all leave" do
      leave_application_count = LeaveApplication.count
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      get :index
      expect(LeaveApplication.count).to eq(leave_application_count + 1)
      should respond_with(:success)
      should render_template(:index)
    end 
  end

  context "Canceling leaves" do
    it "Should be credited in corresponding account"
    it "Admin should be canceled after accepting or rejecting"
    it "Employee should be able to cancel when leaves are not accepted or rejected"
    it "After accepting leaves, employee should not be canceled"
    it "If employee cancel leaves then admin should be notified"
    it "Admin cancel leaves then employee should be notified"
  end

  context 'If user is not Admin should not able to ' do

    before do 
      @user = FactoryGirl.create(:user, email: 'employee1@joshsoftware.com', private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      sign_in @user
    end

    after do
      expect(flash[:error]).to eq("Unauthorize access")
    end

    it ' Approve leave' do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      get :approve_leave, {id: leave_application.id}
    end

    it ' Reject leave' do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      get :cancel_leave, {id: leave_application.id}
    end

  end

  context "Rejecting leaves" do

    before(:each) do
      @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR') 
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      sign_in @admin
    end

    it "Reason should get updated on rejection " do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      reason = 'Invalid Reason'
      get :cancel_leave, {id: leave_application.id, reject_reason: reason}
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected"
      expect(leave_application.reject_reason).to eq reason
    end

    it "Only single mail to employee should get sent on leave rejection" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      get :cancel_leave, {id: leave_application.id}
      Sidekiq::Extensions::DelayedMailer.jobs.size.should eq(1)
    end

    it "should not able to revert to accept status once rejected" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected" 

      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected" 
    end 
  end

  context 'Update', update_leave: true do
    let(:employee) { FactoryGirl.create(:user) }
    let(:leave_app) { FactoryGirl.create(:leave_application, user_id: employee.id) }

    it 'Admin should be able to update leave' do
      sign_in FactoryGirl.create(:admin)
      end_at, days = leave_app.end_at.to_date + 1.day, leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: { "end_at"=> end_at, "number_of_days"=> days }
      l_app = assigns(:leave_application)
      l_app.number_of_days.should eq(days)
      l_app.end_at.should eq(end_at)
    end

    it 'Employee should be able to update his own leave' do
      sign_in employee
      end_at, days = leave_app.end_at.to_date + 1.day, leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: { "end_at"=> end_at, "number_of_days"=> days }
      l_app = assigns(:leave_application)
      l_app.number_of_days.should eq(days)
      l_app.end_at.should eq(end_at)
    end

    it 'Employee should not be able to update leave of other employee' do
      sign_in FactoryGirl.create(:user)
      end_at, days = leave_app.end_at.to_date + 1.day, leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: { "end_at"=> end_at, "number_of_days"=> days }
      expect(flash[:alert]).to eq("You are not authorized to access this page.")
      l_app = assigns(:leave_application)
      expect(l_app.number_of_days).to eq(leave_app.number_of_days)
      expect(l_app.end_at).to eq(leave_app.end_at)
    end

    it 'number of days should get updated if updated' do
      sign_in employee
      number_of_leaves = employee.employee_detail.available_leaves
      end_at, days = leave_app.end_at.to_date + 1.day, leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: { "end_at"=> end_at, "number_of_days"=> days }
      l_app = assigns(:leave_application)
      l_app.number_of_days.should eq(days)
      l_app.end_at.should eq(end_at)
      expect(employee.reload.employee_detail.available_leaves).to eq(number_of_leaves - days)
    end

  end

  context 'Update', update_leave: true do
    let(:employee) { FactoryGirl.create(:user) }
    let(:leave_app) { FactoryGirl.create(:leave_application, user_id: employee.id) }

    it 'should update available leaves if number of days changed' do
      sign_in employee
      end_at, days = leave_app.end_at.to_date + 1.day, leave_app.number_of_days - 1
      employee.employee_detail.available_leaves = 10
      employee.save
      
      post :update, id: leave_app.id, leave_application: { "end_at"=> end_at, "number_of_days"=> days}

      l_app = assigns(:leave_application)

      #TODO
      #expect(employee.reload.employee_detail.available_leaves).to eq(10 - days)
    end
  end
end

