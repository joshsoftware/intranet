require 'spec_helper'

shared_examples "update_leave_details" do 
  it "should be able to update sick available leave " do
    @user.leave_details.last.available_leave["Sick"].should be(SICK_LEAVE) 
    get :update_available_leave, {id: @user.leave_details.last.id, type: 'Sick', value: '2'}
    @user.reload.leave_details.last.available_leave["Sick"].should be(2) 
  end
  
  it "should be able to update Casual available leave " do
    @user.leave_details.last.available_leave["Casual"].should be(CASUAL_LEAVE) 
    get :update_available_leave, {id: @user.leave_details.last.id, type: 'Casual', value: '5'}
    @user.reload.leave_details.last.available_leave["Casual"].should be(5) 
  end
  
  it "should be able to update Casual available leave " do
    @user.leave_details.last.available_leave["TotalPrivilege"].to_f.should be(0.0) 
    get :update_available_leave, {id: @user.leave_details.last.id, type: 'TotalPrivilege', value: '10'}
    @user.reload.leave_details.last.available_leave["TotalPrivilege"].to_f.should be(10.0) 
  end 

  it "should raise error if type not passed" do
    @user.leave_details.last.available_leave["TotalPrivilege"].to_f.should be(0.0) 
    expect{ get :update_available_leave, {id: @user.leave_details.last.id, type: 'Total', value: '10'}}.to raise_error(RuntimeError) 
    
    @user.reload.leave_details.last.available_leave["TotalPrivilege"].to_f.should be(0.0) 
  end 
end

describe LeaveDetailsController do
  context "As an Employee" do
    before(:each) do
      admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR', private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01)))
      sign_in @user
    end

    it "should not be able to update sick available leave " do
      @user.leave_details.last.available_leave["Sick"].should be(SICK_LEAVE) 
      get :update_available_leave, {id: @user.leave_details.last.id, type: 'Sick', value: '2'}
      @user.leave_details.last.available_leave["Sick"].should be(SICK_LEAVE) 
    end
    
    it "should not be able to update Casual available leave " do
      @user.leave_details.last.available_leave["Casual"].should be(CASUAL_LEAVE) 
      get :update_available_leave, {id: @user.leave_details.last.id, type: 'Casual', value: '5'}
      @user.reload.leave_details.last.available_leave["Sick"].should be(CASUAL_LEAVE) 
    end
    
    it "should not be able to update Casual available leave " do
      @user.leave_details.last.available_leave["Privilege"].to_f.should be(0.0) 
      get :update_available_leave, {id: @user.leave_details.last.id, type: 'Casual', value: '5'}
      @user.reload.leave_details.last.available_leave["Privilege"].to_f.should be(0.0) 
    end 
  end

  context "As an HR" do
    before(:each) do
      admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR', private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01)))
      sign_in @hr
    end
    
    it_behaves_like "update_leave_details"
     
  end

  context "As an Admin" do
    before(:each) do
      admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin') 
      @hr = FactoryGirl.create(:user, email: 'hr@joshsoftware.com', role: 'HR', private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01)))
      sign_in admin
    end 
    it_behaves_like "update_leave_details"
  end
end
