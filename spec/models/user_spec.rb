require 'spec_helper'

describe User do  


  it { should have_fields(:email, :encrypted_password, :role, :uid, :provider, :status) }
  it { should have_field(:status).of_type(String).with_default_value_of(STATUS[0]) }
  it { should embed_one :public_profile }
  it { should embed_one :private_profile }
  it { should accept_nested_attributes_for(:public_profile) }
  it { should accept_nested_attributes_for(:private_profile) }
  it { should validate_presence_of(:role) }
  it { should validate_presence_of(:email) }

  
  it "should have employer as default role when created" do
    user = FactoryGirl.build(:user)
    user.role.should eq("Employee")
    user.role?("Employee").should eq(true)
  end 
  
  it "should increment user privilege leave monthly" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month - 1, 01)))
    user.save!
    user.assign_monthly_leave
    user = User.last 
    user.leave_details.first.available_leave["CurrentPrivilege"].to_f.should be(1.5)
    user.leave_details.first.available_leave["TotalPrivilege"].to_f.should be(1.5)
  end

  it "should not increment user privilege leave monthly if previous month days > 15" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month - 1, 19)))
    user.save!
    user.assign_monthly_leave
    user = User.last 
    user.leave_details.first.available_leave["CurrentPrivilege"].to_f.should be(0.0)
    user.leave_details.first.available_leave["TotalPrivilege"].to_f.should be(0.0)
  end

  it "should reset yearly leave with previous year leave < 15" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year - 1, Date.today.month - 1, 19)))
    user.save
    user.reload
    leave_detail = user.leave_details.last
    leave_detail.year = Date.today.year - 1
    leave_detail.available_leave["CurrentPrivilege"] = 13
    leave_detail.available_leave["TotalPrivilege"] = 34 
    leave_detail.save
    user = User.last
    user.set_leave_details_per_year
    user.reload
      
    leave_detail = user.leave_details.last
    leave_detail.available_leave["TotalPrivilege"].to_f.should be(34.0)
    leave_detail.available_leave["CurrentPrivilege"].to_f.should be(0.0)
    leave_detail.available_leave["Sick"].should be(SICK_LEAVE)
    leave_detail.available_leave["Casual"].should be(CASUAL_LEAVE)
  end

  it "should reset yearly leave with previous year leave > 15" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year - 1, Date.today.month - 1, 19)))
    user.save
    user.reload
    leave_detail = user.leave_details.last
    leave_detail.year = Date.today.year - 1
    leave_detail.available_leave["CurrentPrivilege"] = 16
    leave_detail.available_leave["TotalPrivilege"] = 34 
    leave_detail.save
    user = User.last
    user.set_leave_details_per_year
    user.reload
      
    leave_detail = user.leave_details.last
    leave_detail.available_leave["TotalPrivilege"].to_f.should be(33.0)
    leave_detail.available_leave["CurrentPrivilege"].to_f.should be(0.0)
    leave_detail.available_leave["Sick"].should be(SICK_LEAVE)
    leave_detail.available_leave["Casual"].should be(CASUAL_LEAVE)
  end

  it "should reset yearly leave with previous year leave == 15" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year - 1, Date.today.month - 1, 19)))
    user.save
    user.reload
    leave_detail = user.leave_details.last
    leave_detail.year = Date.today.year - 1
    leave_detail.available_leave["CurrentPrivilege"] = 15
    leave_detail.available_leave["TotalPrivilege"] = 34 
    leave_detail.save
    user = User.last
    user.set_leave_details_per_year
    user.reload
      
    leave_detail = user.leave_details.last
    leave_detail.available_leave["TotalPrivilege"].to_f.should be(34.0)
    leave_detail.available_leave["CurrentPrivilege"].to_f.should be(0.0)
    leave_detail.available_leave["Sick"].should be(SICK_LEAVE)
    leave_detail.available_leave["Casual"].should be(CASUAL_LEAVE)
  end 
end
