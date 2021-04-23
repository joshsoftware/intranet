require 'rails_helper'

RSpec.describe TimesheetMonthlyService do
  context 'Timesheet Weekend Report - ' do
    before(:each) do
      @from_date = Date.new(2021,02,01)
      @to_date = Date.new(2021,02,15)
      @emp_one = create_user
      @emp_two = create_user
      @emp_three = create_user
      @emp_one.employee_detail.set(employee_id: '001')
      @emp_two.employee_detail.set(employee_id: '002')
      @emp_three.employee_detail.set(employee_id: '003', location: LOCATIONS[1])
      @active_project = FactoryGirl.create(:project, name: 'ActiveProject')

      @service = TimesheetMonthlyService.new(@from_date, @to_date, @emp_one.email)
    end

    it 'convert_duration_in_hours - should return total duration in hours' do
      response = @service.convert_duration_in_hours(360)
      expect(response).to eq("6.00")
    end

    it 'fetch_weekend_and_holidays - should return country wise holiday list' do
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

    it 'should generate monthly timesheet report as expected' do
      user_leave1 = create_leave(@emp_one, @from_date, @from_date+1, 2)
      time_sheet1 = create_ts_factory(@emp_one, Date.new(2021,02,04), "9:00", "19:00")
      time_sheet2 = create_ts_factory(@emp_one, Date.new(2021,02,06), "9:00", "19:00")
      time_sheet3 = create_ts_factory(@emp_one, Date.new(2021,02,14), "9:00", "20:00")
      time_sheet4 = create_ts_factory(@emp_two, Date.new(2021,02,06), "9:00", "19:00")
      time_sheet5 = create_ts_factory(@emp_two, Date.new(2021,02,8), "9:00", "19:00")
      user_leave2 = create_leave(@emp_two, Date.new(2021,02,8), Date.new(2021,02,8), 1)
      time_sheet6 = create_ts_factory(@emp_two, Date.new(2021,02,07), "9:00", "18:30")
      time_sheet7 = create_ts_factory(@emp_two, Date.new(2021,02,13), "9:00", "21:00")
      time_sheet8 = create_ts_factory(@emp_two, Date.new(2021,02,14), "9:00", "20:00")
      time_sheet9 = create_ts_factory(@emp_three, Date.new(2021,02,06), "9:00", "19:00")
      time_sheet10 = create_ts_factory(@emp_three, Date.new(2021,02,07), "9:00", "18:30")

      report = [
        {
          :location_name=> LOCATIONS[0], #B'luru
          :header=> (@from_date..@to_date).to_a,
          :records=>{},
          :timesheet_per_day_count => {
            :'01/02/2021'=>0, :'02/02/2021'=>0, :'03/02/2021'=>0, :'04/02/2021'=>0, :'05/02/2021'=>0,
            :'06/02/2021'=>0, :'07/02/2021'=>0, :'08/02/2021'=>0, :'09/02/2021'=>0, :'10/02/2021'=>0,
            :'11/02/2021'=>0, :'12/02/2021'=>0, :'13/02/2021'=>0, :'14/02/2021'=>0, :'15/02/2021'=>0
          },
          :holiday => @service.fetch_weekend_and_holidays(COUNTRIES[1]),
          :resigned_emp_name => []
        },
        {
          :location_name=> LOCATIONS[1],
          :header=> (@from_date..@to_date).to_a,
          :records=>{
            @emp_three.id=>{
              :employee_id=> @emp_three.employee_detail.employee_id,
              :user_name=> @emp_three.name,
              :project=> ['ActiveProject'],
              :occurances=> 2,
              :no_of_weekday=> 0,
              :no_of_weekend=> 2,
              :no_of_holiday=> 0,
              :no_of_ts_missing_days=> 11,
              :no_of_leave_day=> 0,
              :timesheet=> {
                :"01/02/2021"=>'NF',  :"02/02/2021"=>'NF',    :"03/02/2021"=>'NF',    :"04/02/2021"=>'NF',
                :"05/02/2021"=>'NF',  :"06/02/2021"=>"10.00", :"07/02/2021"=>"9.30",  :"08/02/2021"=>'NF',
                :"09/02/2021"=>'NF',  :"10/02/2021"=>'NF',    :"11/02/2021"=>'NF',    :"12/02/2021"=>'NF',
                :"13/02/2021"=>'',    :"14/02/2021"=>'',      :"15/02/2021"=>'NF',
              }
            }
          },
          :timesheet_per_day_count => {
            :'01/02/2021'=>0, :'02/02/2021'=>0, :'03/02/2021'=>0, :'04/02/2021'=>0, :'05/02/2021'=>0,
            :'06/02/2021'=>1, :'07/02/2021'=>1, :'08/02/2021'=>0, :'09/02/2021'=>0, :'10/02/2021'=>0,
            :'11/02/2021'=>0, :'12/02/2021'=>0, :'13/02/2021'=>0, :'14/02/2021'=>0, :'15/02/2021'=>0
          },
          :holiday => @service.fetch_weekend_and_holidays(COUNTRIES[1]),
          :resigned_emp_name => []
        },
        {
          :location_name=> LOCATIONS[2],
          :header=> (@from_date..@to_date).to_a,
          :records=>{
            @emp_one.id=>{
              :employee_id=> @emp_one.employee_detail.employee_id,
              :user_name=> @emp_one.name,
              :project=> ['ActiveProject'],
              :occurances=> 3,
              :no_of_weekday=> 1,
              :no_of_weekend=> 2,
              :no_of_holiday=> 0,
              :no_of_ts_missing_days=> 8,
              :no_of_leave_day=> 2,
              :timesheet=> {
                :"01/02/2021"=>'LV',  :"02/02/2021"=>'LV',    :"03/02/2021"=>'NF',  :"04/02/2021"=>'10.00',
                :"05/02/2021"=>'NF',  :"06/02/2021"=>"10.00", :"07/02/2021"=>'',    :"08/02/2021"=>'NF',
                :"09/02/2021"=>'NF',  :"10/02/2021"=>'NF',    :"11/02/2021"=>'NF',  :"12/02/2021"=>'NF',
                :"13/02/2021"=>'',    :"14/02/2021"=>"11.00", :"15/02/2021"=>'NF',
              }
            },

            @emp_two.id=>{
              :employee_id=> @emp_two.employee_detail.employee_id,
              :user_name=> @emp_two.name,
              :project=> ['ActiveProject'],
              :occurances=> 5,
              :no_of_weekday=> 0,
              :no_of_weekend=> 4,
              :no_of_holiday=> 1,
              :no_of_ts_missing_days=> 10,
              :no_of_leave_day=> 1,
              :timesheet=> {
                :"01/02/2021"=>'NF',    :"02/02/2021"=>'NF',    :"03/02/2021"=>'NF',    :"04/02/2021"=>'NF',
                :"05/02/2021"=>'NF',    :"06/02/2021"=>"10.00", :"07/02/2021"=>"9.30",  :"08/02/2021"=>'LV + 10.00',
                :"09/02/2021"=>'NF',    :"10/02/2021"=>'NF',    :"11/02/2021"=>'NF',    :"12/02/2021"=>'NF',
                :"13/02/2021"=>"12.00", :"14/02/2021"=>"11.00", :"15/02/2021"=>'NF',
              }
            }
          },
          :timesheet_per_day_count => {
            :'01/02/2021'=>0, :'02/02/2021'=>0, :'03/02/2021'=>0, :'04/02/2021'=>1, :'05/02/2021'=>0,
            :'06/02/2021'=>2, :'07/02/2021'=>1, :'08/02/2021'=>1, :'09/02/2021'=>0, :'10/02/2021'=>0,
            :'11/02/2021'=>0, :'12/02/2021'=>0, :'13/02/2021'=>1, :'14/02/2021'=>2, :'15/02/2021'=>0
          },
          :holiday => @service.fetch_weekend_and_holidays(COUNTRIES[0]),
          :resigned_emp_name => []
        },
      ]
      response = @service.generate_timesheet_monthly_report
      expect(response).to eq(report)
    end

    it 'should send mail' do
      ActionMailer::Base.deliveries = []
      @service.call
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Timesheet Monthly Report - #{Date.today}")
    end
  end

  def create_ts_factory(user, date, start_time, end_time)
    FactoryGirl.create(
      :time_sheet,
      user: user,
      project: @active_project,
      date: date,
      from_time: "#{date} " + start_time,
      to_time: "#{date} " + end_time
    )
  end

  def create_leave(user, start_at, end_at, no_day)
    user_leave1 = FactoryGirl.create(:leave_application,
      start_at: start_at,
      end_at: end_at,
      leave_status: APPROVED,
      number_of_days: no_day,
      leave_type: LEAVE_TYPES[:leave],
      user: user
    )
  end

  def create_user
    FactoryGirl.create(
      :user,
      allow_backdated_timesheet_entry: true,
      status: STATUS[:approved]
    )
  end
end 