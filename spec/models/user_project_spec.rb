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
      expect(user_project.errors.full_messages).
        to eq(["Allocation can't be blank"])
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
        user_project.end_date = '12/03/2020'.to_date
        user_project.save
        expect(UserProject.find(user_project)).to eq(user_project)
      end
    end
    
  end
end
