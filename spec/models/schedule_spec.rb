require 'spec_helper'

RSpec.describe Schedule, :type => :model do

  context "check time format" do
    it "should have correct time format" do
      schedule = FactoryGirl.build(:schedule)
      expect(schedule.interview_time.class).to eq(ActiveSupport::TimeWithZone)
    end

    it "should not have incorrect time format" do
      schedule = FactoryGirl.build(:schedule)
      schedule.interview_time = "59/23/11"
      expect(schedule.interview_time).not_to match(
        /(([0-1][0-9])|(2[0-3])){1}(:([0-5][0-9])){2}/
      )
    end
  end

  context "check date" do
    it "should have future date" do
      schedule = FactoryGirl.build(:schedule)
      expect(schedule.interview_date < Date.today).to eq(false)
    end

    it "should not have past date" do
      schedule = FactoryGirl.build(:schedule)
      schedule.interview_date = "12/2/1992"
      expect(schedule.interview_date < Date.today).not_to eq(false)
    end
  end

  describe "interview type" do
    
    context "interview type telephonic" do
      it "should have valid telephone no" do
        schedule = FactoryGirl.build(:schedule)
        expect(schedule.candidate_details[:telephone]).to match(/^([0-9]{10})$/)
      end

      it "should not have invalid telephone no" do
        schedule = FactoryGirl.build(:schedule)
        schedule.candidate_details['telephone'] = 3433
        expect(schedule.candidate_details['telephone']).
          not_to match(/^([0-9]{10})$/)
      end
    end

    context "interview type skype" do
      it "should have valid skype id" do
        schedule = FactoryGirl.build(:schedule)
        expect(schedule.candidate_details[:skype]).to match(/^(\w{6,20})$/)
      end

      it "should not have invalid skype id" do
        schedule = FactoryGirl.build(:schedule)
        schedule.candidate_details[:skype] = 'test@11'
        expect(schedule.candidate_details['skype']).not_to match(/^(\w{6,20})$/)
      end
    end 

    context "interview type face to face" do
      it "should have valid phone no or email id" do
        schedule = FactoryGirl.build(:schedule)
        expect(schedule.candidate_details[:telephone]).to match(/^([0-9]{10})$/) or
        expect(schedule.candidate_details[:email]).
            to match(/^([a-z0-9][\w_+]*)*[a-z0-9]@(\w+\.)+\w+$/i)
      end
    end

  end

  describe "check allowable public profiles" do
    context "profile should be github profile" do
      it "should have valid github profile" do
        schedule = FactoryGirl.build(:schedule)
        expect(schedule.public_profile[:git]).to match(/^http:\/\/github.com\/\w*$/)
      end

      it "should not have invalid github profile" do
        schedule = FactoryGirl.build(:schedule)
        schedule.public_profile[:git] = 'http://github.in/78%'
        expect(schedule.public_profile['git']).
          not_to match(/^http:\/\/github.com\/\w*$/)
      end
    end

    context "profile should be linkedin profile" do
      it "should have valid linkedin profile" do
        schedule = FactoryGirl.build(:schedule)
        expect(schedule.public_profile[:linkedin]).
          to match(/^http:\/\/in.linkedin.com\/pub\/(\w|[-\/])*$/)
      end

      it "should not have invalid linkedin profile" do
        schedule = FactoryGirl.build(:schedule)
        schedule.public_profile[:linkedin] = 'http://in.linkedin.com/ad$'
        expect(schedule.public_profile['linkedin']).
          not_to match(/^http:\/\/in.linkedin.com\/pub\/(\w|[-\/])*$/)
      end
    end
  end

  describe "document valiadtion" do
    context "pdf document" do
      it "should have document type .pdf" do
        schedule = FactoryGirl.build(:schedule)
        expect(schedule.file.file.extension.downcase).to eq('pdf')
      end

      it "should not have other format" do
        schedule = FactoryGirl.create(:schedule,
          file: fixture_file_upload('spec/fixtures/files/sample1.doc')
        )
        expect(schedule.file.file.extension.downcase).not_to eq('pdf')
      end
    end

    context "microsoft document" do
      it "should have document type .doc,.docx" do
        schedule = FactoryGirl.create(:schedule,
          file: fixture_file_upload('spec/fixtures/files/sample1.doc')
        )
        expect(['doc','docx'].include?(schedule.file.file.extension.downcase)).
          to eq(true)
      end

      it "should not have other format" do
        schedule = FactoryGirl.create(:schedule)
        expect(['doc','docx'].include?(schedule.file.file.extension.downcase)).
          not_to eq(true)
      end
    end
  end

  context "valid interviewer" do
    it "should have registered email" do
      schedule = FactoryGirl.create(:schedule)
      email = schedule.users.first.email
      expect(User.where(email:email).last.valid?).to eq(true)
    end

    it "should not have non registered email" do
      user = FactoryGirl.build(:user)
      schedule = FactoryGirl.build(:schedule,:users=>[user])
      email = schedule.users.first.email
      expect(User.where(email:email).last).to eq(nil)
    end
  end
end
