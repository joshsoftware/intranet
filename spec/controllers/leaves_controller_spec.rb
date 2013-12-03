require 'spec_helper'

describe LeaveApplicationsController do
  context "Employee, manager and HR" do
    before(:each) do
       
      admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
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
    
    it "should raise exception when submitting leave without entering user date of joining." do
      expect{ post :create, {user_id: @user.id, leave_application: @leave_application.attributes}}.to raise_error(NoMethodError) 
    end

    it "should be able to apply sick leave" do
      leave_type = FactoryGirl.create(:leave_type)
      @user.build_private_profile(FactoryGirl.build(:private_profile).attributes)
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      @user.leave_details.should_not be([])
      post :create, {user_id: @user.id, leave_application: @leave_application.attributes.merge(leave_type_id: leave_type.id, number_of_days: 2)}
      LeaveApplication.count.should == 1 
      @user.reload 
      leave_detail = @user.leave_details.last
      remaining_leave = SICK_LEAVE - @leave_application.number_of_days
      leave_detail.available_leave["Sick"].should be(remaining_leave)
    end
    
    it "should not able to apply leave if not sufficient leave" do
      leave_type = FactoryGirl.create(:leave_type, name: 'Privilege')
      @user.build_private_profile(FactoryGirl.build(:private_profile).attributes)
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      @user.leave_details.should_not be([])
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["TotalPrivilege"] = leave_detail.available_leave["CurrentPrivilege"] = 7
      leave_detail.save
      post :create, {user_id: @user.id, leave_application: @leave_application.attributes.merge(leave_type_id: leave_type.id, number_of_days: 9)}
      LeaveApplication.count.should == 0 
      @user.reload
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["TotalPrivilege"].to_f.should be(7.0)
      leave_detail.available_leave["CurrentPrivilege"].to_f.should be(7.0)
    end
    
    it "should be able to apply privilege leave" do
      leave_type = FactoryGirl.create(:leave_type, name: 'Privilege')
      
      @user.build_private_profile(FactoryGirl.build(:private_profile).attributes)
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      @user.leave_details.should_not be([])
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["TotalPrivilege"] = 19
      leave_detail.available_leave["CurrentPrivilege"] = 19
      leave_detail.save
      @leave_application.attributes.delete("_id")
      post :create, {user_id: @user.id, leave_application: @leave_application.attributes.merge(leave_type_id: leave_type.id, number_of_days: 7)}
      LeaveApplication.count.should == 1 
      @user.reload 
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["TotalPrivilege"].to_f.should be(12.0)  
      leave_detail.available_leave["CurrentPrivilege"].to_f.should be(12.0)  
    end
  end
  
  context "AS HR" do
    before(:each) do
      admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @user = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR', private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      #user = FactoryGirl.create(:user, role: 'Employee')
      sign_in @user
      @leave_application = FactoryGirl.build(:leave_application, user_id: @user.id) 
    end
    
    it "should be able to apply leave" do
      get :new, {user_id: @user.id}
      should respond_with(:success)
      should render_template(:new)
    end

    it "should be able to view all leave" do
      leave_type = FactoryGirl.create(:leave_type, name: 'Sick')
      @leave_application.leave_type_id = leave_type.id
      @leave_application.save
      get :index
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
  
    it "Admin as a role should accept sick leaves " do
      leave_type = FactoryGirl.create(:leave_type)
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["Sick"] = leave_detail.available_leave["Casual"] = SICK_LEAVE - leave_application.number_of_days 
      leave_detail.save
      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Approved" 
    end
    
    it "Admin as a role should accept privilege leaves " do
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["TotalPrivilege"] = leave_detail.available_leave["CurrentPrivilege"] = 9
      leave_detail.save 
      
      leave_type = FactoryGirl.create(:leave_type, name: 'Privilege')
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      leave_detail = @user.reload.leave_details.last
      leave_detail.available_leave["CurrentPrivilege"] = leave_detail.available_leave["TotalPrivilege"] = 9 
      leave_detail.save
      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Approved" 
    end 

    it "Admin as a role should to able perform accept(or reject) only one time" do
      leave_type = FactoryGirl.create(:leave_type)
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["Sick"] = leave_detail.available_leave["Casual"] = SICK_LEAVE - leave_application.number_of_days 
      leave_detail.save
      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Approved" 
      
      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Approved" 
    end 

    it "should be able to apply leave" do
      get :new, {user_id: @admin.id}
      should respond_with(:success)
      should render_template(:new)
    end

    it "should be able to view all leave" do
      leave_type = FactoryGirl.create(:leave_type, name: 'Sick')
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      get :index
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

  context "Rejecting leaves" do
    before(:each) do
      @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR') 
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      sign_in @admin
    end
  
    it "Admin as a role should Reject sick leaves " do
      leave_type = FactoryGirl.create(:leave_type)
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["Sick"] = SICK_LEAVE - leave_application.number_of_days 
      leave_detail.save
      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Rejected"
         
      leave_detail = @user.reload.leave_details.last
      leave_detail.available_leave["Sick"].should eq(SICK_LEAVE)
    end
    
    it "Admin as a role should Reject Casual leaves " do
      leave_type = FactoryGirl.create(:leave_type, name: 'Casual')
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["Casual"] = CASUAL_LEAVE - leave_application.number_of_days 
      leave_detail.save!
      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Rejected"
         
      leave_detail = @user.reload.leave_details.last
      leave_detail.available_leave["Casual"].should eq(CASUAL_LEAVE)
    end
   
 
    it "Admin as a role should reject privilege leaves " do
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["TotalPrivilege"] = leave_detail.available_leave["CurrentPrivilege"] = 9
      leave_detail.save

      leave_type = FactoryGirl.create(:leave_type, name: 'Privilege')
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      
      leave_detail.available_leave["TotalPrivilege"] = leave_detail.available_leave["CurrentPrivilege"] = 9 - leave_application.number_of_days
      leave_detail.save
      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Rejected"
       
      leave_detail = @user.reload.leave_details.last
      leave_detail.available_leave["TotalPrivilege"].to_f.should eq(9.0)
      leave_detail.available_leave["CurrentPrivilege"].to_f.should eq(9.0)
    end 

    it "should not able to revert to accept status once rejected" do
      leave_type = FactoryGirl.create(:leave_type)
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, leave_type_id: leave_type.id)
      leave_detail = @user.leave_details.last
      leave_detail.available_leave["Sick"] = leave_detail.available_leave["Casual"] = SICK_LEAVE - leave_application.number_of_days 
      leave_detail.save
      get :cancel_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Rejected" 
      
      get :approve_leave, {id: leave_application.id}
      leave_application = LeaveApplication.last
      leave_application.leave_status.should == "Rejected" 
    end 
  end
end

