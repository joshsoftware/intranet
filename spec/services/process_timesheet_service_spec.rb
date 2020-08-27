require 'rails_helper'

RSpec.describe ProcessTimesheetService do
  context 'Process and Create Timesheets - ' do 
    before(:all) do
      @file = Rails.root.join('spec/fixtures/files/timesheets.csv')
      @service = ProcessTimesheetService.new
      @params = { 
        Email: 'test@joshsoftware.com',
        Project: 'Brand Scope',
        Date: '18/05/2020',
        Duration: '540',
        Description: 'Testing',
        Status: ''
      }.as_json
    end
  
    it 'Timesheet Created Successfully' do
      FactoryGirl.create(:user, email: 'test@joshsoftware.com')
      FactoryGirl.create(:project, name: 'Brand Scope')
      response = @service.call(@params)
      
      expect(response.last).to eq('Timesheet Created Successfully')
    end

    it 'Error - User Invalid' do
      response = @service.call(@params)

      expect(response.last).to eq("User Email ID not found" +
        " \nProject Not Found. Please check project name")
    end

    it 'Error - Project Invalid' do
      FactoryGirl.create(:user, email: 'test@joshsoftware.com')
      response = @service.call(@params)

      expect(response.last).to eq('Project Not Found. Please check project name')
    end

    it 'Error - Record Already Exists' do
      user = FactoryGirl.create(:user, email: 'test@joshsoftware.com')
      project = FactoryGirl.create(:project, name: 'Brand Scope')
      timesheet = FactoryGirl.build(:time_sheet, user: user,
                                                 project: project,
                                                 date: '18/05/2020'.to_date,
                                                 from_time: nil,
                                                 to_time: nil,
                                                 duration: 540,
                                                 description: 'Testing')
      timesheet.save(:validate => false)
      response = @service.call(@params)
      
      expect(response.last).to eq('Timesheet record already Exists')
    end

    it 'Error - Working Hours exceeded' do
      user = FactoryGirl.create(:user, email: 'test@joshsoftware.com')
      project = FactoryGirl.create(:project, name: 'Brand Scope')
      timesheet = FactoryGirl.build(:time_sheet, user: user,
                                                 project: project,
                                                 date: '18/05/2020'.to_date,
                                                 from_time: nil,
                                                 to_time: nil,
                                                 duration: 1400,
                                                 description: 'Testing')
      timesheet.save(:validate => false)
      response = @service.call(@params)
      
      expect(response.last).to eq("Timesheet total working hours can't exceed 24 hours.")
    end

    it 'Timesheet record created successfully' do
      user = FactoryGirl.create(:user, email: 'test@joshsoftware.com')
      project = FactoryGirl.create(:project, name: 'Brand Scope')
      timesheet = FactoryGirl.build(:time_sheet, user: user,
                                                 project: project,
                                                 date: '18/05/2020'.to_date,
                                                 from_time: nil,
                                                 to_time: nil,
                                                 duration: 540,
                                                 description: 'Testing File')
      timesheet.save(:validate => false)
      response = @service.call(@params)
      
      expect(response.last).to eq('Timesheet Created Successfully')
    end
  end

  context 'Uploaded Timesheet Report ' do

    before(:all) do
      FactoryGirl.create(:user, email: 'test@joshsoftware.com')
      FactoryGirl.create(:project, name: 'Brand Scope')
      @hr = FactoryGirl.create(:hr)
    end

    it 'send mail after processing the uploaded file' do
      Sidekiq::Testing.inline! do
        file_path = Rails.root.join('spec/fixtures/files/timesheets.csv')
        file_name = 'Testing'
        email = @hr.email
        
        ImportTimesheetWorker.perform_async(file_path, file_name, email)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.subject).to eq('Result for Uploaded Timesheet File')
      end
    end
  end
end