require 'rails_helper'

RSpec.describe UserProject, type: :model do
  context 'validation' do
    
    it 'Should success' do
      user_project = FactoryGirl.create(:user_project)
      expect(user_project).to be_present
    end
    
    it 'Should fail because user id not present' do
      user_project = FactoryGirl.build(:user_project)
      user_project.user_id = nil
      user_project.save
      expect(user_project.errors.full_messages).to eq(["User can't be blank"])
    end
    
    it 'Should fail because project id not present' do
      user_project = FactoryGirl.build(:user_project)
      user_project.project_id = nil
      user_project.save
      expect(user_project.errors.full_messages).
        to eq(["Project can't be blank"])
    end
    
    it 'Should fail because start date not present' do
      user_project = FactoryGirl.build(:user_project)
      user_project.start_date = nil
      user_project.save
      expect(user_project.errors.full_messages).
        to eq(["Start date can't be blank"])
    end

    it 'Should fail because active not present' do
      user_project = FactoryGirl.build(:user_project)
      user_project.active = nil
      user_project.save
      expect(user_project.errors.full_messages).
        to eq(["Active can't be blank"])
    end

    it 'Should fail because allocation not present' do
      user_project = FactoryGirl.build(:user_project)
      user_project.allocation = nil
      user_project.save
      expect(user_project.errors.full_messages.first).
        to eq("Allocation can't be blank")
    end

    it 'Should fail because allocation is greater than 100' do
      user_project = FactoryGirl.build(:user_project)
      user_project.allocation = 101
      user_project.save
      expect(user_project.errors.full_messages).
        to eq(["Allocation not less than 0 & not more than 160"])
    end

    context 'end_date compulsory if user is inactive' do
      it 'Should fail because end date not present' do
        user_project = FactoryGirl.build(:user_project)
        user_project.active = false
        user_project.end_date = nil
        user_project.save
        expect(user_project.errors.full_messages).
          to eq(["End date is mandatory to mark inactive"])
      end

      it 'Should pass if end_date is present' do
        user_project = FactoryGirl.build(:user_project)
        user_project.active = false
        user_project.end_date = Date.today
        user_project.save
        expect(UserProject.find(user_project)).to eq(user_project)
      end
    end

    it 'should validate end_date greater than start_date' do
      user = FactoryGirl.create(:user)
      project = FactoryGirl.create(:project)
      user_project = FactoryGirl.build(:user_project, user: user, project: project, start_date: Date.today, end_date: Date.yesterday)
      user_project.save
      expect(user_project.errors[:end_date]).to eq(['should not be less than start date.'])
    end

    context 'user_id should be unique for active users' do
      it 'Should fail because duplcate active users are not allowed' do
        project = FactoryGirl.create(:project)
        user = FactoryGirl.create(:user)
        FactoryGirl.create(:user_project, project_id: project.id, user_id: user.id)
        user_project = FactoryGirl.build(:user_project, project_id: project.id, user_id: user.id)
        user_project.save
        expect(user_project.errors.full_messages).to eq(["User is already taken"])
      end

      it 'Should pass because duplicate inactive users are allowed' do
        project = FactoryGirl.create(:project)
        user = FactoryGirl.create(:user)
        FactoryGirl.create(:user_project, project_id: project.id, user_id: user.id, active: false, end_date: Date.today)
        user_project = FactoryGirl.build(:user_project, project_id: project.id, user_id: user.id)
        user_project.save
        expect(UserProject.find(user_project)).to eq(user_project)
      end
    end
  end

  context 'Trigger - should call code monitor service' do
    before(:each) do 
      @project = build(:project)
      stub_request(:get, "http://localhost?event_type=Project%20Active&project_id=#{@project.id}").
        with(
          headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host'=>'example.com',
          'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})
      @project.save
      @user = FactoryGirl.create(:user)
    end

    it 'when user is added in the project' do
      user_project = FactoryGirl.build(:user_project, project_id: @project.id, user_id: @user.id)
      stub_request(:get, "http://localhost?event_type=User%20Added&project_id=#{@project.id}&user_id=#{@user.id}").
        with(
          headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Host'=>'example.com',
        'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})

      user_project.save
      expect(@project.user_projects.count).to eq 1
    end

    it 'when user is removed from the project' do
      user_project = FactoryGirl.build(:user_project, project_id: @project.id, user_id: @user.id)
      stub_request(:get, "http://localhost?event_type=User%20Added&project_id=#{@project.id}&user_id=#{@user.id}").
        with(
          headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Host'=>'example.com',
        'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})
      user_project.save

      stub_request(:get, "http://localhost?event_type=User%20Removed&project_id=#{@project.id}&user_id=#{@user.id}").
        with(
          headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host'=>'example.com',
          'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})
      user_project.update_attributes(active: false, end_date: Date.today)
      expect(@project.user_projects.count).to eq 1
      expect(user_project.active).to eq false
    end
  end
end
