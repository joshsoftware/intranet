require 'rails_helper'

RSpec.describe TimesheetWeekendService do
  context 'Timesheet Weekend Report - ' do
    before(:each) do
      @from_date = Date.new(2021,02,01)
      @to_date = Date.new(2021,02,16)
      @emp_one = FactoryGirl.create(
        :user,
        allow_backdated_timesheet_entry: true,
        status: STATUS[:approved]
      )
      @emp_two = FactoryGirl.create(
        :user,
        allow_backdated_timesheet_entry: true,
        status: STATUS[:approved]
      )
      @emp_three = FactoryGirl.create(
        :user,
        allow_backdated_timesheet_entry: true,
        status: STATUS[:approved]
      )
      @emp_one.employee_detail.set(employee_id: '001')
      @emp_two.employee_detail.set(employee_id: '002')
      @emp_three.employee_detail.set(employee_id: '003', location: LOCATIONS[1])
      @active_project = FactoryGirl.create(:project, name: 'ActiveProject')

      @service = TimesheetWeekendService.new(@from_date, @to_date, @emp_one.email)
    end

    it 'convert_duration_in_hours - should return total duration in hours' do
      response = @service.convert_duration_in_hours(360)
      expect(response).to eq("6h 00min")
    end

    it 'convert_duration_in_hours - should return total duration in hours' do
      weekend_and_holidays = []
      HolidayList.list(COUNTRIES[0]).pluck(:holiday_date).each do |h|
        weekend_and_holidays << h.to_date
      end
      weekend = [0,6]
      (@from_date..@to_date).each do |date|
        weekend_and_holidays << date if weekend.include?(date.wday)
      end
      response = @service.fetch_weekend_and_holidays(COUNTRIES[0])
      expect(response).to eq(weekend_and_holidays)
    end

    it 'should generate resource report as expected' do
      time_sheet1 = FactoryGirl.create(
        :time_sheet,
        user: @emp_one,
        project: @active_project,
        date: Date.new(2021,02,06),
        from_time: "#{Date.new(2021,02,06)} 9:00",
        to_time: "#{Date.new(2021,02,06)} 10:00"
      )
      time_sheet2 = FactoryGirl.create(
        :time_sheet,
        user: @emp_one,
        project: @active_project,
        date: Date.new(2021,02,14),
        from_time: "#{Date.new(2021,02,14)} 9:00",
        to_time: "#{Date.new(2021,02,14)} 10:00"
      )
      time_sheet3 = FactoryGirl.create(
        :time_sheet,
        user: @emp_two,
        project: @active_project,
        date: Date.new(2021,02,13),
        from_time: "#{Date.new(2021,02,13)} 9:00",
        to_time: "#{Date.new(2021,02,13)} 10:00"
      )
      time_sheet4 = FactoryGirl.create(
        :time_sheet,
        user: @emp_three,
        project: @active_project,
        date: Date.new(2021,02,14),
        from_time: "#{Date.new(2021,02,14)} 10:00",
        to_time: "#{Date.new(2021,02,14)} 11:00"
      )

      report = [
        {
          :country_name=> COUNTRIES[0],
          :header=> @service.fetch_weekend_and_holidays(COUNTRIES[0]),
          :records=>{
            :"#{@emp_one.employee_detail.employee_id}"=>{
              :user_name=> @emp_one.name,
              :"06/02/2021"=>"1h 00min",
              :"07/02/2021"=>"-",
              :"13/02/2021"=>"-",
              :"14/02/2021"=>"1h 00min"
              },
            :"#{@emp_two.employee_detail.employee_id}"=>{
              :user_name=> @emp_two.name,
              :"06/02/2021"=>"-",
              :"07/02/2021"=>"-",
              :"13/02/2021"=>"1h 00min",
              :"14/02/2021"=>"-"
            }
          }
        },
        {
          :country_name=> COUNTRIES[1],
          :header=> @service.fetch_weekend_and_holidays(COUNTRIES[1]),
          :records=>{
            :"#{@emp_three.employee_detail.employee_id}"=>{
              :user_name=> @emp_three.name,
              :"06/02/2021"=>"-",
              :"07/02/2021"=>"-",
              :"13/02/2021"=>"-",
              :"14/02/2021"=>"1h 00min"
            }
          }
        }
      ]
      response = @service.generate_timesheet_weekend_report
      expect(response).to eq(report)
    end

    it 'should send mail' do
      ActionMailer::Base.deliveries = []
      @service.call
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Timesheet Weekend Report - #{Date.today}")
    end
  end
end