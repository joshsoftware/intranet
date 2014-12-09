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
  
  it "intern should not eligible for leave" do
    user = FactoryGirl.build(:user, role: 'Intern', email: 'intern@company.com')
    user.save
    user.eligible_for_leave?.should be(false) 
  end

  it "nil date of joining employee should not eligible for leave" do
    user = FactoryGirl.build(:user, email: 'employee@company.com')
    user.save
    user.eligible_for_leave?.should be(false) 
  end 
  
  it "valid employee should be eligible for leave" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month, 01).prev_month))
    user.save!
     
    user.eligible_for_leave?.should be(true) 
  end 
  

  it "should reset yearly leave" do
    user = FactoryGirl.build(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year - 1, Date.today.month, 19).prev_month))
    user.save
    user.reload
    user.set_leave_details_per_year
    user.reload
    expect(user.employee_detail.available_leaves).to eq(PER_MONTH_LEAVE*12)
  end

  context "sent mail for approval" do

    ##### check date of joining in case of specs fail
    before (:each) do
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month, 19)))
      @user.save
    end

    it "should send email if HR and admin roles are present" do
      hr_user = FactoryGirl.create(:user, role: "HR", email: "hr@joshsoftware.com", password: "josh123", private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month, 19) - 10.month))
      admin_user = FactoryGirl.create(:user, role: "Admin", email: "admin@joshsoftware.com", password: "josh123", private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month, 19) - 10.month))
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id)
      expect{@user.sent_mail_for_approval(leave_application)}.not_to raise_error
    end

    it "should send email if HR role is absent" do
      admin_user = FactoryGirl.create(:user, role: "Admin", email: "admin@joshsoftware.com", password: "josh123", private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month, 19) - 10.month))
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id)
      User.where(role: 'HR').should eq([])
      expect{@user.sent_mail_for_approval(leave_application)}.not_to raise_error
    end
    
    it "should send email if admin role is absent" do
      hr_user = FactoryGirl.create(:user, role: "HR", email: "hr@joshsoftware.com", password: "josh123", private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, Date.today.month, 19) - 10.month))
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id)
      User.where(role: 'Admin').should eq([])
      expect{@user.sent_mail_for_approval(leave_application)}.not_to raise_error
    end

    it "should send email if hr and admin roles are absent" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id)
      User.where(role: 'Admin').should eq([])
      User.where(role: 'HR').should eq([])
      expect{@user.sent_mail_for_approval(leave_application)}.not_to raise_error
    end
  end
end
