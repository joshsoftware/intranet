require 'spec_helper'

describe UsersController do
  
  context "Inviting user" do
    before(:each) do
      @admin = FactoryGirl.create(:user, role: 'Admin', email: "admin@joshsoftware.com")
      sign_in @admin
    end

    it 'In order to invite user' do
      get :invite_user
      should respond_with(:success)
      should render_template(:invite_user)
    end

    it 'should not invite user without email and role' do
      post :invite_user, {user: {email: "", role: ""}}
      should render_template(:invite_user)
    end

    it 'invitee should have joshsoftware account' do
      post :invite_user, {user: {email: "invitee@joshsoftware.com", role: "Employee"}}
      flash.notice.should eql("Invitation sent Succesfully")
      User.count.should == 2
    end

  end
  context "update" do
    before(:each) do
      @user = FactoryGirl.create(:user, role: 'Employee', email: 'sanjiv@joshsoftware.com', 
              public_profile: FactoryGirl.build(:public_profile), private_profile: FactoryGirl.build(:private_profile))
      sign_in @user
    end
    it "public_profile" do
      params = {"public_profile"=>{"first_name" => "sanjiv", "last_name"=>"Jha", "gender"=>"Male", "mobile_number"=>"9595808669", 
                 "blood_group"=>"A+", "date_of_birth"=>"15-10-2013", "skills"=>"", "github_handle"=>"", 
                 "twitter_handle"=>"", "blog_url"=>""}, "id" => @user.id }
      put :public_profile, params
    
      @user.errors.full_messages.should eq([])
    end

    it "should fail in case of public profile if required field missing" do
      params = {"public_profile"=>{"last_name"=>"Jha", "gender"=>"Male", "mobile_number"=>"", "blood_group"=>"A+", 
                "date_of_birth"=>"15-10-2013", "skills"=>"", "github_handle"=>"", "twitter_handle"=>"", "blog_url"=>""}, 
                "id"=> @user.id}

      put :public_profile, params
      @user.errors.full_messages.should_not eq(nil)
    end

    it "private profile successfully " do
      params = {"private_profile" => {"pan_number"=> @user.private_profile.pan_number, "personal_email"=>"narutosanjiv@gmail.com", 
                "passport_number" =>"", "qualification"=>"BE", "date_of_joining"=>"01-01-2013",  
                "work_experience"=>"", "previous_company"=>"", "id" => @user.private_profile.id}, "id"=> @user.id}

      put :private_profile, params
      @user.errors.full_messages.should eq([])
    end

    it "should fail if required data not sent" do
      params = {"private_profile" => {"pan_number"=> @user.private_profile.pan_number, "personal_email"=>"", 
                "passport_number" =>"", "qualification"=>"BE", "date_of_joining"=>"01-01-2013",
                "work_experience"=>"", "previous_company"=>"", "id" => @user.private_profile.id}, "id"=> @user.id}

      put :private_profile, params
      @user.errors.full_messages.should eq([])
    end
  end
end
