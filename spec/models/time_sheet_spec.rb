require 'rails_helper'

RSpec.describe TimeSheet, type: :model do
  context 'Validation' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:user_project) { FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: DateTime.now - 4
      )
    }

    #Slack related specs
    # before do
    #   user.public_profile.slack_handle = USER_ID
    #   stub_request(:post, "https://slack.com/api/chat.postMessage")
    # end

    # it 'Should success' do
    #   params = {
    #     'user_id' => USER_ID, 
    #     'channel_id' => CHANNEL_ID, 
    #     'text' => "The_pediatric_network #{Date.yesterday}  6 7 abcd efghigk lmnop"
    #   }

    #   ret = time_sheet.parse_timesheet_data(params)
    #   expect(ret[0]).to eq(true)
    # end

    # it 'Should success even if project name is lower case' do
    #   params = {
    #     'user_id' => USER_ID,
    #     'channel_id' => CHANNEL_ID,
    #     'text' => "the_pediatric_network #{Date.yesterday}  6 7 abcd efghigk lmnop"
    #   }

    #   ret = time_sheet.parse_timesheet_data(params)
    #   expect(ret[0]).to eq(true)
    # end

    it 'Should fails because record is already present' do
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 10:00",
        to_time: "#{Date.today - 1} 11:00",
        description: 'call'
      )
      time_sheet = FactoryGirl.build(:time_sheet,
        user: user,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 10:00",
        to_time: "#{Date.today - 1} 11:00",
        description: 'call'
      )
      time_sheet.save
      expect(time_sheet.errors.full_messages).to eq(
        ['From time Record already present',
         'To time Record already present']
      )
    end

    #Slack related specs
    # it 'Should return false because invalid timesheet command format' do
    #   params = {
    #     'user_id' => USER_ID, 
    #     'channel_id' => CHANNEL_ID, 
    #     'text' => 'England_Hockey 22-07-2018  6'
    #   }

    #   expect(time_sheet.parse_timesheet_data(params)).to eq(false)
    # end

    # it 'Should return false because user does not assign to this project' do
    #   params = {
    #     'user_id' => USER_ID, 
    #     'channel_id' => CHANNEL_ID,
    #     'text' => 'England 14-07-2018  6 7 abcd efgh'
    #   }
    #   expect(time_sheet.parse_timesheet_data(params)).to eq(false)
    # end

    context 'Date should' do
      #Slack related spec
      # it 'Should return false because invalid date format' do
      #   params = {
      #     'user_id' => USER_ID,
      #     'channel_id' => CHANNEL_ID,
      #     'text' => 'England_Hockey 14-2018  6 7 abcd efgh'
      #   }
      #   expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      # end
#removed this validation when user are allowed to fill timesheet irrespective of assigned date.
      # it 'fail because date is greater than assigned project date' do
      #   time_sheet = FactoryGirl.build(:time_sheet,
      #     date: DateTime.now - 5,
      #     user: user,
      #     project: project
      #   )
      #   expect(time_sheet.save).to eq(false)
      #   expect(time_sheet.errors[:date]).to eq(
      #     ['Not allowed to fill timesheet for this date. As you were not assigned on project for this date']
      #   )
      # end

      it 'fail because date is not within this week' do
        time_sheet = FactoryGirl.build(:time_sheet, date: DateTime.now - 10)
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:date]).to eq(
          ['Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.']
        )
      end

      #Slack related spec
      # it 'Should return false because date is invalid' do
      #   params = {
      #     'user_id' => USER_ID,
      #     'channel_id' => CHANNEL_ID,
      #     'text' => 'The_pediatric_network 1/32/2018  6 7 abcd efgh'
      #   }
      #   expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      # end

      it 'fail because date and time is greater than current date and time' do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: Date.tomorrow,
          from_time: "#{Date.tomorrow} 20:00",
          to_time: "#{Date.tomorrow} 20:30"
        )
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:date]).
          to eq(["Can't fill the timesheet for future date."])
      end

      #Code is changed
      # it 'Should not update record because date is less than 2 days' do
      #   time_sheet = FactoryGirl.create(:time_sheet,
      #     user: user,
      #     project: project,
      #     date: Date.today - 4,
      #     from_time: "#{Date.today - 4} 6:00",
      #     to_time: "#{Date.today - 4} 7:00"
      #   )
      #   time_sheet.update_attributes(description: 'call')
      #   expect(time_sheet.errors.full_messages).to eq(
      #     ["Not allowed to edit timesheet for this date. You can edit timesheet for past 2 days."]
      #   )
      # end

      it 'pass and update timesheet' do
        time_sheet = FactoryGirl.create(:time_sheet,
          user: user,
          project: project,    
          date: Date.today - 2,
          from_time: "#{Date.today - 2} 6:00",
          to_time: "#{Date.today - 2} 7:00"
        )
        time_sheet.update_attributes(description: 'call')
        expect(time_sheet.errors.full_messages).to eq([])
        expect(time_sheet.reload.description).to eq('call')
      end

      it 'fail because date is not present' do
        time_sheet = FactoryGirl.build(:time_sheet, date: nil)
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:date]).to eq(['Invalid time'])
      end
    end

    context 'Time should' do
      #Slack related specs
      # it 'Should return false because invalid from time format' do
      #   params = {
      #     'user_id' => USER_ID,
      #     'channel_id' => CHANNEL_ID,
      #     'text' => "The_pediatric_network #{Date.yesterday} 15.30 16 abcd efg"
      #   }
      #   expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      # end

      # it 'Should return false because invalid to time format' do
      #   params = {
      #     'user_id' => USER_ID,
      #     'channel_id' => CHANNEL_ID,
      #     'text' => "The_pediatric_network #{Date.yesterday} 6 7.00 abcd efg"
      #   }
      #   expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      # end

      it "fail because 'from time' is greater than 'to time'" do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: DateTime.now - 1,
          from_time: "#{Date.today - 1} 8:00",
          to_time: "#{Date.today - 1} 7:00"
        )
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:from_time]).
          to eq(["From time must be less than to time"])
      end
    end

    context 'Timesheet time duration should fail because' do
      before do
        FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 7",
          to_time: "#{Date.today - 1} 10",
        )
      end

      it "'to time' is in already entered time duration" do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 6",
          to_time: "#{Date.today - 1} 8"
        )
        time_sheet.save
        expect(time_sheet.errors[:from_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
        expect(time_sheet.errors[:to_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
      end

      it "'from time' is in already entered time duration" do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 9",
          to_time: "#{Date.today - 1} 11"
        )
        time_sheet.save
        expect(time_sheet.errors[:from_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
        expect(time_sheet.errors[:to_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
      end

      it "'from time' & 'to time' both are in already entered time duration" do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 8:30",
          to_time: "#{Date.today - 1} 9:30"
        )
        time_sheet.save
        expect(time_sheet.errors[:from_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
        expect(time_sheet.errors[:to_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
      end

      it "'from time' & 'to time' overlaps with already entered time duration'" do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 6",
          to_time: "#{Date.today - 1} 12"
        )
        time_sheet.save
        expect(time_sheet.errors[:from_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
        expect(time_sheet.errors[:to_time]).to eq(
          ['Time duration is overlapping with already entered time duration for the day']
        )
      end
    end

    context 'Duration' do
      it 'should fail if from_time, to_time and duration is absent' do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: DateTime.now - 1,
          from_time: nil,
          to_time: nil,
          duration: nil
        )
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:duration]).
          to eq(["can't be blank"])
      end

      it 'should fail if duration is nil and one of from_time and to_time is present and other absent' do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: DateTime.now - 1,
          from_time: "#{Date.today} 10:00",
          to_time: nil,
          duration: nil
        )
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:to_time]).to eq(["can't be blank"])
      end

      it 'should pass if duration is present' do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: DateTime.now - 1,
          duration: 90,
          from_time: nil,
          to_time: nil
        )
        expect(time_sheet.save).to eq(true)
        expect(time_sheet.duration).to eq(90)
        expect(time_sheet.from_time).to eq(nil)
        expect(time_sheet.to_time).to eq(nil)
      end

      it 'should always calculate duration and succeed if valid from_time and to_time present' do
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 10:00",
          to_time: "#{Date.today - 1} 11:30",
          duration: 30
        )
        time_sheet.save
        expect(time_sheet.save).to eq(true)
        expect(time_sheet.duration).to eq(90)
      end

      it "should fail to save if total worked hours of a day exceed #{TimeSheet::WORKING_HOURS_THRESHOLD} hours" do
        FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: Date.today - 1,
          from_time: "#{Date.today - 1} 01:00",
          to_time: "#{Date.today - 1} 20:30"
        )
        time_sheet = FactoryGirl.build(:time_sheet,
          user: user,
          project: project,
          from_time: nil,
          to_time: nil,
          date: Date.today - 1,
          duration: 300
        )
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:duration]).to eq(["total working hours can't exceed #{TimeSheet::WORKING_HOURS_THRESHOLD} hours"])
      end
    end
  end

  context 'Timesheet parse_timesheet_data' do
    it 'Should return data for valid request' do
      user = FactoryGirl.create(:user)
      project = FactoryGirl.create(:project)
      user.public_profile.slack_handle = 'rubylover'
      user.public_profile.save
      user_project = FactoryGirl.create(:user_project, user: user, project: project)
      timesheet = FactoryGirl.create(:time_sheet, created_at: Date.yesterday, description: 'abcd efg')
      params = {
        'user_id' => 'rubylover',
        'channel_id' => 'dummy',
        'text' => "#{project.name} #{Date.yesterday} 10 11 abcd efg"
      }
      return_value, timesheet_data = timesheet.parse_timesheet_data(params)
      expected_data = {
        'user_id' => user.id,
        'project_id' => project.id,
        'date' => timesheet.date,
        'from_time' => timesheet.from_time,
        'to_time' => timesheet.to_time,
        'description' => timesheet.description.split().join(' ') + ' '
      }
      expect(return_value).to eq(true)
      expect(timesheet_data).to eq(expected_data)
    end
  end

  context 'Summary report' do
    it 'should create all employee summary' do
      user1 = FactoryGirl.create(:user, status: 'approved')
      user2 = FactoryGirl.create(:user, status: 'approved')
      project1 = FactoryGirl.create(:project)
      project2 = FactoryGirl.create(:project)
      FactoryGirl.create(:user_project, user: user1, project: project1)
      FactoryGirl.create(:user_project, user: user2, project: project1)
      FactoryGirl.create(:user_project, user: user1, project: project2)
      timesheet1 = FactoryGirl.create(:time_sheet, user: user1, project: project1)
      timesheet2 = FactoryGirl.create(:time_sheet, user: user2, project: project1)
      timesheet3 = FactoryGirl.create(:time_sheet, user: user1, project: project2, from_time: "#{Date.yesterday} 11:00", to_time: "#{Date.yesterday} 12:00")
      timesheet_summary = TimeSheet.create_all_employee_summary(Date.yesterday-1, Date.today)
      expected_summary = [{
            emp_id: '1',
            user_name: user1.public_profile.name,
            total_worked_hours: 2
          },
          {
            emp_id: '2',
            user_name: user2.public_profile.name,
            total_worked_hours: 1
      }]
      timesheet_summary = timesheet_summary.sort_by { |timesheet| timesheet[:emp_id] }
      expect(timesheet_summary).to eq(expected_summary)
    end
  end

  context 'Timesheet reminder' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    context 'success' do
      it 'Should give the message to fill timesheet' do
        project = FactoryGirl.create(:project)
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: Date.today - 5
        )
        # date dependant testcase, on weekends this was causing failures an
        if Date.today.sunday?
          date = Date.today - 3
        elsif Date.today.saturday?
          date = Date.today - 2
        else
          date = Date.today - 1
        end
        FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: date,
          from_time: "#{date} 9:00",
          to_time: "#{date} 10:00"
        )
        expect(HolidayList.is_holiday?(user.time_sheets[0].date + 1)).
          to eq(false)
        expect(TimeSheet.time_sheet_present_for_reminder?(user)).to eq(true)
        expect(TimeSheet.user_on_leave?(user, user.time_sheets[0].date + 1)).
          to eq(false)
        expect(
          TimeSheet.time_sheet_filled?(user, user.time_sheets[0].date + 1)
        ).to eq(false)
        expect(TimeSheet.unfilled_timesheet_present?(user,
            user.time_sheets[0].date + 1
          )
        ).to eq(true)
      end
    end

    context 'timesheet filled' do
      let!(:project) { FactoryGirl.create(:project) }
      before do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: DateTime.now - 5
        )
        for x in 1..3
          FactoryGirl.create(:time_sheet,
            user: user,
            project: project,
            date: Date.today - x,
            from_time: "#{Date.today - x} 9:00",
            to_time: "#{Date.today - x} 10:00"
          )
        end
      end

      it 'Should return false because timesheet is not filled' do
        expect(TimeSheet.time_sheet_filled?(user, 4.days.ago.utc)).to eq(false)
      end

      it 'Should return true because timesheet is filled' do
        expect(TimeSheet.time_sheet_filled?(user, Date.today - 1)).to eq(true)
      end
    end

    context 'user on leave' do
      it 'Should return false because leave application is not present' do
        expect(TimeSheet.user_on_leave?(user, Date.today - 2)).to eq(false)
      end

      it 'Should return true because user is on leave' do
        FactoryGirl.create(:leave_application,
          user: user,
          leave_status: LEAVE_STATUS[1]
        )
        expect(TimeSheet.user_on_leave?(user, Date.today + 2)).to eq(true)
      end

      it 'Should return false because user is not on leave' do
        FactoryGirl.create(:leave_application,
          user: user,
          leave_status: LEAVE_STATUS[1]
        )
        expect(TimeSheet.user_on_leave?(user, Date.today + 4)).to eq(false)
      end
    end
  end

  context 'Daily timesheet status' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.build(:project) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }
    before do
      project.name = 'Test project'
      project.display_name = 'Test_project'
      project.save
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: DateTime.now - 2
      )
    end

    #Slack related specs
    # before do
    #   project.name = 'The pediatric network'
    #   project.display_name = 'The_pediatric_network'
    #   project.save
    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: DateTime.now - 2
    #   )
    #   user.public_profile.slack_handle = USER_ID
    #   user.save
    #   stub_request(:post, "https://slack.com/api/chat.postMessage")
    # end

    # context 'command without option' do
    #   it 'Should give timesheet log' do
    #     FactoryGirl.create(:time_sheet,
    #       user: user,
    #       project: project,
    #       date: Date.today,
    #       from_time: '9:00',
    #       to_time: '10:00',
    #       description: 'Today I finish the work'
    #     )
    #     params = {
    #       'user_id' => USER_ID,
    #       'channel_id' => CHANNEL_ID,
    #       'text' => ""
    #     }
    #     time_sheets = TimeSheet.parse_daily_status_command(params)
    #     expect(time_sheets).to eq(
    #       "You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n"
    #     )
    #   end

    #   it 'Should return false because timesheet record not present' do
    #     params = {
    #       'user_id' => USER_ID,
    #       'channel_id' => CHANNEL_ID,
    #       'text' => ""
    #     }

    #     time_sheets = TimeSheet.parse_daily_status_command(params)
    #     expect(time_sheets).to eq(false)
    #   end
    # end

    # context 'command with options' do
    #   it 'Should give timesheet log' do
    #     FactoryGirl.create(:timesheet,
    #       user: user,
    #       project: project,
    #       date: DateTime.yesterday,
    #       from_time: Time.parse("#{Date.yesterday} 9:00"),
    #       to_time: Time.parse("#{Date.yesterday} 10:00"),
    #       description: 'Today I finish the work'
    #     )
    #     params = {
    #       'user_id' => USER_ID,
    #       'channel_id' => CHANNEL_ID,
    #       'text' => Date.yesterday.to_s,
    #       'command' => '/daily_status'
    #     }
    #     time_sheets = TimeSheet.parse_daily_status_command(params)
    #     expect(time_sheets).to eq(
    #       "You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n"
    #     )
    #   end

    #   it 'Should return false because timesheet record not present' do
    #     params = {
    #       'user_id' => USER_ID,
    #       'channel_id' => CHANNEL_ID,
    #       'text' => Date.yesterday.to_s,
    #       'command' => '/daily_status'
    #     }
    #     time_sheets = TimeSheet.parse_daily_status_command(params)
    #     expect(time_sheets).to eq(false)
    #   end

    #   it 'Should return false because invalid date format' do
    #     params = {
    #       'user_id' => USER_ID,
    #       'channel_id' => CHANNEL_ID,
    #       'text' => '06/07'
    #     }

    #     time_sheets = TimeSheet.parse_daily_status_command(params)
    #     expect(time_sheets).to eq(false)
    #   end

    #   it 'Should return false because invalid date' do
    #     params = {
    #       'user_id' => USER_ID,
    #       'channel_id' => CHANNEL_ID,
    #       'text' => '06/13/2018'
    #     }

    #     time_sheets = TimeSheet.parse_daily_status_command(params)
    #     expect(time_sheets).to eq(false)
    #   end
    # end

    it 'Should give right hours and minutes' do
      total_minutes = 359
      local_var_hours = total_minutes / 60
      local_var_minutes = total_minutes % 60
      hours, minutes = TimeSheet.calculate_hours_and_minutes(total_minutes)
      expect(hours).to eq(local_var_hours)
      expect(minutes).to eq("#{local_var_minutes}")
    end

    it 'Should give right difference between time' do
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: DateTime.yesterday,
        from_time: Time.parse("#{Date.yesterday} 9:00"),
        to_time: Time.parse("#{Date.yesterday} 10:00")
      )
      user_time_sheet = user.time_sheets[0]
      time_diff = TimeDifference.between(
        user_time_sheet.to_time,
        user_time_sheet.from_time
      ).in_minutes
      minutes = TimeSheet.calculate_working_minutes(user_time_sheet)
      expect(minutes).to eq(time_diff)
    end
  end

  context 'Employee timesheet report' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }
    let!(:project) { FactoryGirl.build(:project) }
    before do
      project.name = 'Test project'
      project.display_name = 'Test_project'
      project.save
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: DateTime.now - 2
      )
    end 

    it 'Should give the project name' do
      expect(TimeSheet.get_project_name(project.id)).to eq(project.name)
    end

    it 'Should give the correct hours and minutes' do
      milliseconds = 7200000
      local_var_hours = milliseconds / (1000 * 60 * 60)
      local_var_minutes = milliseconds / (1000 * 60) % 60
      local_var_hours =
        local_var_minutes < 30 ? local_var_hours : local_var_hours + 1
      expect(TimeSheet.convert_milliseconds_to_hours(milliseconds)).
        to eq(local_var_hours)
    end

    it 'Should give the user leaves count' do
      FactoryGirl.create(:leave_application,
        user: user,
        leave_status: LEAVE_STATUS[1]
      )
      expect(TimeSheet.approved_leaves_count(
        user,
        Date.today + 2,
        Date.today + 3
      )).to eq(2)
    end

    it 'Should return true because from date is less than to date' do
      from_date = Date.today - 2
      to_date = Date.today
      expect(TimeSheet.from_date_less_than_to_date?(from_date, to_date)).
        to eq(true)
    end

    it 'Should return true because from date is equal to to date' do
      from_date = Date.today
      to_date = Date.today
      expect(TimeSheet.from_date_less_than_to_date?(from_date, to_date)).
        to eq(true)
    end

    it 'Should return false because from date is greater than to date' do
      from_date = Date.today + 2
      to_date = Date.today
      expect(TimeSheet.from_date_less_than_to_date?(from_date, to_date)).
        to eq(false)
    end

    it 'Should give the expected JSON' do
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: DateTime.yesterday,
        from_time: Time.parse("#{Date.yesterday} 9:00"),
        to_time: Time.parse("#{Date.yesterday} 10:00"),
        description: 'Today I finish the work'
      )
      params = { from_date: Date.yesterday - 1, to_date: Date.today }
      timesheet_record = TimeSheet.load_timesheet(
        user.time_sheets.pluck(:id),
        Date.yesterday - 1,
        Date.today
      )
      timesheet_data = TimeSheet.generate_employee_timesheet_report(
        timesheet_record,
        Date.yesterday - 1,
        Date.today,
        user
      )
      expect(timesheet_data[0][0]['user_name']).to eq("#{user.name}")
      expect(timesheet_data[0][0]['project_details'][0]['project_name']).
        to eq("#{project.name}")
      expect(timesheet_data[0][0]['project_details'][0]['worked_hours']).
        to eq('0 Days 1h (1h)')
      expect(timesheet_data[0][0]['total_worked_hours']).
        to eq('0 Days 1h (1h)')
      expect(timesheet_data[0][0]['leaves']).to eq(0)
    end
  end

  context 'Individual timesheet report' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }
    let!(:test_project1) { FactoryGirl.build(:project) }
    let!(:test_project2) { FactoryGirl.build(:project) }

    it 'Should give expected JSON' do
      test_project1.name = 'Test project1'
      test_project1.display_name = 'Test_project1'
      test_project1.save
      test_project2.name = 'Test project2'
      test_project2.display_name = 'Test_project2'
      test_project2.save
      FactoryGirl.create(:user_project,
        user: user,
        project: test_project1,
        start_date: DateTime.now - 3
      )
      FactoryGirl.create(:user_project,
        user: user,
        project: test_project2,
        start_date: DateTime.now - 3
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: test_project1,
        date: DateTime.yesterday,
        from_time: Time.parse("#{Date.yesterday} 9:00"),
        to_time: Time.parse("#{Date.yesterday} 10:00"),
        description: 'Today I finish the work'
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: test_project2,
        date: DateTime.yesterday,
        from_time: Time.parse("#{Date.yesterday} 11:00"),
        to_time: Time.parse("#{Date.yesterday} 13:30"),
        description: 'Today I finish the work'
      )
      params = { from_date: Date.yesterday - 1, to_date: Date.today }
      individual_time_sheet_data, total_work_and_leaves =
        TimeSheet.generate_individual_timesheet_report(user, params)
      expect(individual_time_sheet_data.count).to eq(2)
      expect(
        individual_time_sheet_data['Test project1']['total_worked_hours']).
          to eq('0 Days 1h (1h)'
      )
      expect(
        individual_time_sheet_data[
          'Test project1'
        ]['daily_status'][0][0]['date'].to_s
      ).to eq(DateTime.yesterday.to_s)
      expect(
        individual_time_sheet_data[
          'Test project1'
        ]['daily_status'][0][0]['from_time']
      ).to eq('09:00AM')
      expect(
        individual_time_sheet_data[
          'Test project1'
        ]['daily_status'][0][0]['to_time']
      ).to eq('10:00AM')
      expect(
        individual_time_sheet_data[
          'Test project1'
        ]['daily_status'][0][0]['total_worked']
      ).to eq('1:00')
      expect(
        individual_time_sheet_data[
          'Test project1'
        ]['daily_status'][0][0]['description']
      ).to eq('Today I finish the work')
      expect(
        individual_time_sheet_data['Test project2']['total_worked_hours']
      ).to eq('0 Days 3h (3h)')
      expect(total_work_and_leaves['total_work']).
      to eq('0 Days 4h (4h)')
      expect(total_work_and_leaves['leaves']).to eq(0)
    end
  end


  context 'Get allocated hours should calculate allocated hours' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project) }

    context "between 'from date' and 'to date'" do
      it 'if there is no holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '01/08/2018'
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("13 Days (104h)")
      end

      it 'if there is one holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '01/08/2018'
        )
        FactoryGirl.create(:holiday, holiday_date: '13/09/2018'.to_date)
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("12 Days (96h)")
      end
    end

    context "from user's project start date and end date" do
      it 'if there is no holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '05/09/2018',
          end_date: '15/09/2018'
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("8 Days (64h)")
      end

      it 'if there is one holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '05/09/2018',
          end_date: '15/09/2018'
        )
        FactoryGirl.create(:holiday, holiday_date: '13/09/2018'.to_date)
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("7 Days (56h)")
      end
    end

    context "from user's project start date and searching to date" do
      it 'if there is no holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '06/09/2018'
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("10 Days (80h)")
      end

      it 'if there is one holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '06/09/2018'
        )
        FactoryGirl.create(:holiday, holiday_date: '13/09/2018'.to_date)
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("9 Days (72h)")
      end
    end

    context "from searching start date and user's project end date" do
      it 'if there is no holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '01/08/2018',
          end_date: '06/09/2018'
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("3 Days (24h)")
      end

      it 'if there is one holiday' do
        FactoryGirl.create(:user_project,
          user: user,
          project: project,
          start_date: '01/08/2018',
          end_date: '06/09/2018'
        )
        FactoryGirl.create(:holiday, holiday_date: '05/09/2018'.to_date)
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("2 Days (16h)")
      end
    end

    context 'in above all scenario' do
      let!(:user_one) { FactoryGirl.create(:user, status: STATUS[2]) }
      let!(:user_two) { FactoryGirl.create(:user, status: STATUS[2]) }
      let!(:user_three) { FactoryGirl.create(:user, status: STATUS[2]) }
      let!(:user_four) { FactoryGirl.create(:user, status: STATUS[2]) }

      it 'should calculate correct allocated hours' do
        FactoryGirl.create(:user_project,
          user: user_one,
          project: project,
          start_date: '01/08/2018'
        )
        FactoryGirl.create(:user_project,
          user: user_two,
          project: project,
          start_date: '05/09/2018',
          end_date: '15/09/2018'
        )
        FactoryGirl.create(:user_project,
          user: user_three,
          project: project,
          start_date: '06/09/2018'
        )
        FactoryGirl.create(:user_project,
          user: user_four,
          project: project,
          start_date: '01/08/2018',
          end_date: '06/09/2018'
        )
        FactoryGirl.create(:holiday, holiday_date: '05/09/2018'.to_date)
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(
          project, from_date, to_date
        )
        expect(allocated_hours).to eq("31 Days (248h)")
      end
    end
  end

  context 'get leaves count should calculate leaves' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project) }

    it "between 'from date' and 'to date'" do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: '01/08/2018'
      )
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '14/09/2018',
        end_at: '14/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      leave_count = TimeSheet.get_leaves(project, from_date, to_date)
      expect(leave_count).to eq(1)
    end

    it "from user's project start date and end date" do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: '05/09/2018',
        end_date: '15/09/2018'
      )
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '14/09/2018',
        end_at: '14/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '13/09/2018',
        end_at: '13/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      leave_count = TimeSheet.get_leaves(project, from_date, to_date)
      expect(leave_count).to eq(2)
    end

    it "from user's project start date and searching to date" do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: '06/09/2018'
      )
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '14/09/2018',
        end_at: '14/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '13/09/2018',
        end_at: '13/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      leave_count = TimeSheet.get_leaves(project, from_date, to_date)
      expect(leave_count).to eq(2)
    end

    it "from searching start date and user's project end date" do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: '01/08/2018',
        end_date: '06/09/2018'
      )
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '03/09/2018',
        end_at: '03/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: '13/09/2018',
        end_at: '13/09/2018',
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      leave_count = TimeSheet.get_leaves(project, from_date, to_date)
      expect(leave_count).to eq(1)
    end
  end

  context 'Project report' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should give expected project report' do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: Date.today - 20
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 19:00",
        to_time: "#{Date.today - 1} 20:00"
      )
      date = Date.today - 4
      date = date - 2.days if date.saturday? || date.sunday?
      FactoryGirl.create(:holiday, holiday_date: date)
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: Date.today - 2,
        end_at: Date.today - 2,
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      from_date = Date.today - 20
      to_date = Date.today
      load_projects_report = TimeSheet.load_projects_report(from_date, to_date)
      projects_report, project_without_timesheet =
        TimeSheet.create_projects_report_in_json_format(
          load_projects_report, from_date, to_date
        )
      expect(projects_report[0]["project_name"]).to eq("#{project.name}")
      expect(projects_report[0]["no_of_employee"]).to eq(1)
      expect(projects_report[0]["total_hours"]).to eq("0 Days 1h (1h)")
      expect(projects_report[0]["allocated_hours"]).to eq("13 Days (104h)")
      expect(projects_report[0]["leaves"]).to eq(1)
      expect(project_without_timesheet.present?).to eq(false)
    end

    it 'Should give project without timesheet' do
      test_project_one = FactoryGirl.create(:project,
        name: 'test1',
        timesheet_mandatory: true
      )
      test_project_two = FactoryGirl.create(:project,
        name: 'test2',
        timesheet_mandatory: true
      )
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: Date.today - 20
      )
      FactoryGirl.create(:user_project,
        user: user,
        project: test_project_one,
        start_date: Date.today - 20
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 9:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      from_date = Date.today - 30
      to_date = Date.today - 1
      load_projects_report = TimeSheet.load_projects_report(from_date, to_date)
      projects_report, project_without_timesheet, users_without_timesheet =
        TimeSheet.create_projects_report_in_json_format(
          load_projects_report, from_date, to_date
        )
      expect(project_without_timesheet.count).to eq(2)
      expect(project_without_timesheet[0]['project_name']).to eq('test1')
      expect(project_without_timesheet[1]['project_name']).to eq('test2')
    end

    #'create_projects_report_in_json_format' does not return users_without_timesheet
    # it 'Should give users without timesheet' do
    #   user_two = FactoryGirl.create(:user, status: STATUS[2])
    #   user_three = FactoryGirl.create(:user, status: STATUS[2])

    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: Date.today - 20
    #   )
    #   FactoryGirl.create(:user_project,
    #     user: user_two,
    #     project: project,
    #     start_date: Date.today - 20
    #   )
    #   FactoryGirl.create(:user_project,
    #     user: user_three,
    #     project: project,
    #     start_date: Date.today - 20
    #   )
    #   FactoryGirl.create(:time_sheet,
    #     user: user,
    #     project: project,
    #     date: Date.today - 1,
    #     from_time: "#{Date.today - 1} 21:00",
    #     to_time: "#{Date.today - 1} 22:00"
    #   )
    #   from_date = Date.today - 20
    #   to_date = Date.today
    #   load_projects_report = TimeSheet.load_projects_report(from_date, to_date)
    #   projects_report, project_without_timesheet, users_without_timesheet =
    #     TimeSheet.create_projects_report_in_json_format(
    #       load_projects_report, from_date, to_date
    #     )
    #   expect(users_without_timesheet[0].email).to eq(
    #     users_without_timesheet[0].email
    #   )
    #   expect(users_without_timesheet[1].email).to eq(
    #     users_without_timesheet[1].email
    #   )
    # end
  end

  context 'Individual project report' do
    let!(:user_one) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:user_two) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:user_three) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should give the expected project report' do
      user_one.public_profile.update_attributes(
        first_name: 'test1_user',
        last_name: 'test1_user'
      )
      user_two.public_profile.update_attributes(
        first_name: 'test2_user',
        last_name: 'test2_user'
      )
      user_three.public_profile.update_attributes(
        first_name: 'test3_user',
        last_name: 'test3_user'
      )
      FactoryGirl.create(:user_project,
        user: user_one,
        project: project,
        start_date: '01/08/2018'
      )
      FactoryGirl.create(:user_project,
        user: user_two,
        project: project,
        start_date: '06/09/2018'
      )
      FactoryGirl.create(:time_sheet,
        user: user_one,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 21:00",
        to_time: "#{Date.today - 1} 22:00"
      )
      FactoryGirl.create(:time_sheet,
        user: user_one,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 8:00",
        to_time: "#{Date.today - 1} 9:00"
      )
      FactoryGirl.create(:time_sheet,
        user: user_one,
        project: project,
        date: Date.today - 2,
        from_time: "#{Date.today - 1} 21:00",
        to_time: "#{Date.today - 1} 22:00"
      )
      FactoryGirl.create(:leave_application,
        user: user_one,
        start_at: Date.today - 10,
        end_at: Date.today - 7,
        number_of_days: 3,
        leave_status: LEAVE_STATUS[1]
      )
      FactoryGirl.create(:time_sheet,
        user: user_two,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 21:00",
        to_time: "#{Date.today - 1} 22:00"
      )
      FactoryGirl.create(:time_sheet,
        user: user_two,
        project: project,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 8:00",
        to_time: "#{Date.today - 1} 10:00"
      )
      FactoryGirl.create(:leave_application,
        user: user_three,
        start_at: '12/09/2018',
        end_at: '13/09/2018',
        number_of_days: 2,
        leave_status: LEAVE_STATUS[1]
      )

      params = { from_date: Date.today - 20, to_date: Date.today }
      individual_project_report, project_report =
      TimeSheet.generate_individual_project_report(project, params)

      expect(
        individual_project_report['test1_user test1_user'][0]['total_work']
      ).to eq('0 Days 3h (3h)')
      expect(
        individual_project_report['test1_user test1_user'][0]['allocated_hours']
      ).to eq('14 Days (112h)')
      expect(
        individual_project_report['test1_user test1_user'][0]['leaves']
      ).to eq(3)
      expect(
        individual_project_report['test2_user test2_user'][0]['total_work']
      ).to eq('0 Days 3h (3h)')
      expect(
        individual_project_report['test2_user test2_user'][0]['allocated_hours']
      ).to eq('14 Days (112h)')
      expect(
        individual_project_report['test2_user test2_user'][0]['leaves']
      ).to eq(0)
      expect(project_report['total_worked_hours']).to eq('0 Days 6h (6h)')
      expect(project_report['total_allocated_hourse']).to eq('28 Days (224h)')
      expect(project_report['total_leaves']).to eq(3)
    end
  end

  context 'Generate weekly report in csv format' do
    it 'Should generate csv' do
      headers = ['Employee name', 'Project name', 'No of days worked', 'Leaves', 'Holidays']
      weekly_report = [
        ['employee_test1', 'project_test1', '0 days 6h (6h)', 1, 0],
        ['employee_test2', 'project_test2', '0 days 3h (3h)', 2, 1]
      ]
      csv = TimeSheet.generate_report_in_csv_format(headers, weekly_report)
      expect(csv).to eq(
        "Employee name,Project name,No of days worked,Leaves,Holidays\nemployee_test1,project_test1,0 days 6h (6h),1,0\nemployee_test2,project_test2,0 days 3h (3h),2,1\n"
      )
    end
  end

  context 'Get holiday count' do
    it 'Should give holiday count' do
      FactoryGirl.create(:holiday, holiday_date: '09/10/2018'.to_date)
      FactoryGirl.create(:holiday, holiday_date: '11/10/2018'.to_date)
      from_date = '05/10/2018'.to_date
      to_date = '15/10/2018'.to_date
      count = TimeSheet.get_holiday_count(from_date, to_date)
      expect(count).to eq(2)
    end

    it 'Should give holiday count 0' do
      FactoryGirl.create(:holiday, holiday_date: '09/10/2018'.to_date)
      FactoryGirl.create(:holiday, holiday_date: '11/10/2018'.to_date)
      from_date = '01/10/2018'.to_date
      to_date = '05/10/2018'.to_date
      count = TimeSheet.get_holiday_count(from_date, to_date)
      expect(count).to eq(0)
    end
  end

  context 'Get time sheet and calculate total minutes should' do
    let!(:user) { FactoryGirl.create(:user) }
    it 'give total working minutes' do
      project = FactoryGirl.create(:project)
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: Date.today - 10
      )
      for d in 10..12
        FactoryGirl.create(:time_sheet,
          user: user,
          project: project,
          date: DateTime.now - 1,
          from_time: Time.parse("#{Date.today - 1} #{d}"),
          to_time: Time.parse("#{Date.today - 1} #{d+1}")
        )
      end
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user, project, from_date, to_date
        )
      expect(total_minutes).to eq(180.0)
    end

    it 'give the users without timesheet because user role is employee' do
      project = FactoryGirl.create(:project)
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: Date.today - 10
      )
      FactoryGirl.create(:leave_application,
        user: user,
        start_at: Date.today - 1,
        end_at: Date.today- 1,
        number_of_days: 1,
        leave_status: LEAVE_STATUS[1]
      )
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user, project, from_date, to_date
        )
      expect(total_minutes).to eq(0)
      expect(users_without_timesheet).
        to eq(["#{user.name}", "#{project.name}", 1])
    end

    it 'give users without timesheet because role is intern' do
      project = FactoryGirl.create(:project)
      user_two = FactoryGirl.create(:user, role: 'Intern')
      FactoryGirl.create(:user_project,
        user: user_two,
        project: project,
        start_date: Date.today - 10
      )
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user_two, project, from_date, to_date
        )
      expect(total_minutes).to eq(0)
      expect(users_without_timesheet).
        to eq(["#{user_two.name}", "#{project.name}", 0])
    end

    it 'not give the uses without timesheet because user role is manager' do
      project = FactoryGirl.create(:project)
      user_two = FactoryGirl.create(:user, role: 'Manager')
      FactoryGirl.create(:user_project,
        user: user_two,
        project: project,
        start_date: Date.today - 10
      )
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user_two, project, from_date, to_date
        )
      expect(users_without_timesheet.present?).to eq(false)
    end

    it 'not give the uses without timesheet because user role is admin' do
      project = FactoryGirl.create(:project, timesheet_mandatory: true)
      user_two = FactoryGirl.create(:admin)
      FactoryGirl.create(:user_project,
        user: user_two,
        project: project,
        start_date: Date.today - 10
      )
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user_two, project, from_date, to_date
        )
    end

    it "consider project for calculating total minutes if project's timesheet mandatory field set to false" do
      project_other = FactoryGirl.create(:project, timesheet_mandatory: false)
      FactoryGirl.create(:user_project,
        user: user,
        project: project_other,
        start_date: Date.today - 10
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project_other,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 8:00",
        to_time: "#{Date.today - 1} 9:00"
      )
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user, project_other, from_date, to_date
        )
      expect(total_minutes).to eq(60.0)
    end

    it 'not consider project whose timesheet mandatory field set to false for users without timesheet list' do
      project_other = FactoryGirl.create(:project, timesheet_mandatory: false)
      FactoryGirl.create(:user_project,
        user: user,
        project: project_other,
        start_date: Date.today - 10
      )
      FactoryGirl.create(:time_sheet,
        user: user,
        project: project_other,
        date: Date.today - 1,
        from_time: "#{Date.today - 1} 8:00",
        to_time: "#{Date.today - 1} 9:00"
      )
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet =
        TimeSheet.get_time_sheet_and_calculate_total_minutes(
          user, project_other, from_date, to_date
        )
      expect(users_without_timesheet.present?).to eq(false)
    end
  end

  context 'Update timesheet' do
    let!(:user) { FactoryGirl.create(:admin) }
    let!(:project) { FactoryGirl.create(:project) }
  
    #'check_validation_while_updating_time_sheet' is undefined method
    # it 'Should give return value true' do
    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: Date.today - 10
    #   )
    #   time_sheet = FactoryGirl.create(:time_sheet,
    #                   user: user,
    #                   project: project,
    #                   date: Date.today - 1,
    #                   from_time: Time.parse("#{Date.today - 1} 10"),
    #                   to_time: Time.parse("#{Date.today - 1} 11:30")
    #                 )
    #   params = {
    #               time_sheets_attributes: {
    #                 "0" => { 
    #                          project_id: "#{project.id}",
    #                          date: "#{Date.today - 1}",
    #                          from_time: "#{Date.today - 1} - 09:00 AM",
    #                          to_time: "#{Date.today - 1} - 11:15 AM",
    #                          description: "testing API and call with client",
    #                          id:"#{time_sheet.id}"
    #                        }
    #                 },
    #               id: user.id
    #            }
    #   return_value =
    #     TimeSheet.check_validation_while_updating_time_sheet(params)
    #   expect(return_value).to eq(true)
    # end
  
    # it 'Should give error from time less than to time' do
    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: Date.today - 10
    #   )
    #   time_sheet = FactoryGirl.create(:time_sheet,
    #                   user: user,
    #                   project: project,
    #                   date: Date.today - 1,
    #                   from_time: Time.parse("#{Date.today - 1} 10"),
    #                   to_time: Time.parse("#{Date.today - 1} 11:30")
    #                 )
    #   params = {
    #               time_sheets_attributes: {
    #                 "0" => {
    #                           project_id: "#{project.id}",
    #                           date: "#{Date.today - 1}",
    #                           from_time: "#{Date.today - 1} - 10:00 AM",
    #                           to_time: "#{Date.today - 1} - 09:00 AM",
    #                           description:"",
    #                           id: "#{time_sheet.id}"
    #                        }
    #                 },
    #               id: user.id
    #            }
    #   return_value =
    #     TimeSheet.check_validation_while_updating_time_sheet(params)
    #   expect(return_value).to eq("Error :: From time must be less than to time")
    # end
  
    # it 'Should give error not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager' do
    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: Date.today - 10
    #   )
    #   time_sheet = FactoryGirl.create(:time_sheet,
    #                   user: user,
    #                   project: project,
    #                   date: Date.today - 1,
    #                   from_time: Time.parse("#{Date.today - 1} 10"),
    #                   to_time: Time.parse("#{Date.today - 1} 11:30"),
    #                 )
    #   params = {
    #               time_sheets_attributes: {
    #                 "0" => {
    #                           project_id: "",
    #                           date: "#{Date.today - 10}",
    #                           from_time: "#{Date.today - 1} - 09:00 AM",
    #                           to_time: "#{Date.today - 1} - 11:15 AM",
    #                           description: "",
    #                           id: "#{time_sheet.id}"
    #                        }
    #                 },
    #               id: user.id
    #            }
    #   return_value = TimeSheet.check_validation_while_updating_time_sheet(params)
    #   expect(return_value).to eq(
    #     'Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.'
    #   )
    # end
  
    # it "Should give error can't fill the timesheet for future time" do
    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: Date.today - 10
    #   )
    #   time_sheet = FactoryGirl.create(:time_sheet,
    #                   user: user,
    #                   project: project,
    #                   date: Date.today - 1,
    #                   from_time: Time.parse("#{Date.today - 1} 10"),
    #                   to_time: Time.parse("#{Date.today - 1} 11:30"),
    #                 )
    #   params = {
    #               time_sheets_attributes: {
    #                 "0" => {
    #                           project_id: "",
    #                           date: "#{Date.today}",
    #                           from_time: "#{DateTime.now + 3.minutes}",
    #                           to_time: "#{DateTime.now + 5.minutes}",
    #                           description: "",
    #                           id: "#{time_sheet.id}"
    #                        }
    #                 },
    #               id: user.id
    #            }
    #   return_value =
    #     TimeSheet.check_validation_while_updating_time_sheet(params)
    #   expect(return_value).to eq(
    #     "Error :: Can't fill the timesheet for future time."
    #   )
    # end
  
    # it 'Should give error not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.' do
    #   FactoryGirl.create(:user_project,
    #     user: user,
    #     project: project,
    #     start_date: Date.today - 10
    #   )
    #   time_sheet = FactoryGirl.create(:time_sheet,
    #                   user: user,
    #                   project: project,
    #                   date: Date.today - 1,
    #                   from_time: Time.parse("#{Date.today - 1} 10"),
    #                   to_time: Time.parse("#{Date.today - 1} 11:30")
    #                 )
    #   params = {
    #               time_sheets_attributes: {
    #                 "0" => {
    #                           project_id: "",
    #                           date: "#{Date.today - 10}",
    #                           from_time: "#{DateTime.now + 3.minutes}",
    #                           to_time: "#{DateTime.now + 5.minutes}",
    #                           description: "",
    #                           id: "#{time_sheet.id}"
    #                        }
    #                 },
    #               id: user.id
    #            }
    #   return_value =
    #     TimeSheet.check_validation_while_updating_time_sheet(params)
    #   expect(return_value).to eq(
    #     'Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.'
    #   )
    # end
  end

  # context 'Export project report' do
  #   let!(:user_one) { FactoryGirl.create(:user) }
  #   let!(:user_two) { FactoryGirl.create(:user) }
  #   let!(:project) { FactoryGirl.create(:project) }
    
    # it 'Should give the project report' do
    #   user_one.public_profile.first_name = 'Aaaaa'
    #   user_one.save
    #   FactoryGirl.create(:user_project,
    #     user: user_one,
    #     project: project,
    #     start_date: Date.today - 20
    #   )
    #   FactoryGirl.create(:user_project,
    #     user: user_two,
    #     project: project,
    #     start_date: Date.today - 20
    #   )
    #   FactoryGirl.create(:time_sheet,
    #     user: user_one,
    #     project: project,
    #     date: Date.today - 3,
    #     from_time: "#{Date.today - 3} 10",
    #     to_time: "#{Date.today - 3} 11",
    #     description: 'Test api'
    #   )
    #   FactoryGirl.create(:time_sheet,
    #     user: user_one,
    #     project: project,
    #     date: Date.today - 3,
    #     from_time: "#{Date.today - 3} 12",
    #     to_time: "#{Date.today - 3} 13",
    #     description: 'call with client'
    #   )
    #   FactoryGirl.create(:time_sheet,
    #     user: user_two,
    #     project: project,
    #     date: Date.today - 2,
    #     from_time: "#{Date.today - 2} 1",
    #     to_time: "#{Date.today - 2} 2",
    #     description: 'test data'
    #   )
    #   from_date = Date.today - 20
    #   to_date = Date.today
    #   project_report = TimeSheet.create_project_report_in_csv(project, from_date, to_date)
    #   expect(project_report).to eq("Employee name,Date(dd/mm/yyyy),No of hours,Details\n#{user_one.name},#{(Date.today - 3).strftime('%d-%m-%Y')},2,\"Test api\ncall with client\"\n#{user_two.name},#{(Date.today - 2).strftime('%d-%m-%Y')},1,test data\n")
    # end
  # end

  #Slack related specs
  # context 'Api test' do
  #   it 'Invalid time sheet format : Should return true ' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: Invalid timesheet format. Fromat should be <project_name> <date> <from_time> <to_time> <description>\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_invalid_date' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Not assigned project : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: you are not working on this project. Use /projects command to view your project\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_not_assign_project' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Invalid date format : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_invalid_date_format' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Date range : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: Date should be in last week\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason__date_in_last_week' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Date range : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: Date should be in last week\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason__date_in_last_week' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'From time should be less than to time : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: From time must be less than to time\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason__from_time_is_less' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'From time should be less than to time : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: From time must be less than to time\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason__from_time_is_less' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Invalid time format : Should return true' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: Invalid time format. Format should be HH:MM\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason__invalid_time' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Record is already present : should return true' do
  #     text = "\` Error :: From time record is already present, To time record is already present\`"
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => text
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_record_already_present' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       ret = JSON.parse(response.body)
  #       expect(ret['ok']).to eq(true)
  #     end
  #   end

  #   it 'Should return false because invalid slack token' do
  #     slack_params = {
  #       'token' => 'abcd.efghi.gklmno',
  #       'channel' => CHANNEL_ID,
  #       'text' => "\`Error :: Invalid time format\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_invalid_slack_token' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       resp = JSON.parse(response.body)
  #       expect(resp['ok']).to eq(false)
  #       expect(resp['error']).to eq('invalid_auth')
  #     end
  #   end

  #   it 'Should return false because invalid channel id' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => 'UU12345',
  #       'text' => "\`Error :: Channel not found\`"
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_invalid_channel_id' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       resp = JSON.parse(response.body)
  #       expect(resp['ok']).to eq(false)
  #       expect(resp['error']).to eq('channel_not_found')
  #     end
  #   end

  #   it 'Should return false because text is empty' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'channel' => CHANNEL_ID,
  #       'text' => ""
  #     }
  #     VCR.use_cassette 'timesheet_failure_reason_empty_text' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/chat.postMessage"),
  #                     slack_params
  #                   )
  #       resp = JSON.parse(response.body)
  #       expect(resp['ok']).to eq(false)
  #       expect(resp['error']).to eq('no_text')
  #     end
  #   end

  #   it 'Should return true because user id is valid' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'user' => USER_ID
  #     }
  #     VCR.use_cassette 'success_user_info' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/users.info"),
  #                     slack_params
  #                   )
  #       resp = JSON.parse(response.body)
  #       expect(resp['ok']).to eq(true)
  #     end
  #   end

  #   it 'Should return false because user id is invalid' do
  #     slack_params = {
  #       'token' => SLACK_API_TOKEN,
  #       'user' => 'ABCD8F'
  #     }
  #     VCR.use_cassette 'failure_user_info' do
  #       response = Net::HTTP.post_form(
  #                     URI("https://slack.com/api/users.info"),
  #                     slack_params
  #                   )
  #       resp = JSON.parse(response.body)
  #       expect(resp['ok']).to eq(false)
  #       expect(resp['error']).to eq('user_not_found')
  #     end
  #   end

  #   context 'im open API' do
  #     it 'Should success to create new channel and closed that channel' do
  #       new_channel = ''
  #       slack_params_for_im_open = {
  #         'token' => SLACK_API_TOKEN,
  #         'user' => USER_ID
  #       }

  #       VCR.use_cassette('success_im_open') do
  #         response = Net::HTTP.post_form(
  #                       URI("https://slack.com/api/im.open"),
  #                       slack_params_for_im_open
  #                     )
  #         resp = JSON.parse(response.body)
  #         new_channel = resp['channel']['id']
  #         expect(resp['ok']).to eq(true)
  #         expect(new_channel.present?).to eq(true)
  #       end

  #       slack_params_for_im_close = {
  #         'token' => SLACK_API_TOKEN,
  #         'channel' => new_channel
  #       }

  #       VCR.use_cassette('success_im_close') do
  #         response = Net::HTTP.post_form(
  #                       URI("https://slack.com/api/im.close"),
  #                       slack_params_for_im_close
  #                     )
  #         resp = JSON.parse(response.body)
  #         expect(resp['ok']).to eq(true)
  #       end
  #     end

  #     context 'failure' do
  #       it 'Should fail im open api because user id invalid' do
  #         slack_params = {
  #           'token' => SLACK_API_TOKEN,
  #           'user' => 'ABC123'
  #         }

  #         VCR.use_cassette 'failure_im_open_reason_invalid_user_id' do
  #           response = Net::HTTP.post_form(
  #                         URI("https://slack.com/api/im.open"),
  #                         slack_params
  #                       )
  #           resp = JSON.parse(response.body)
  #           expect(resp['ok']).to eq(false)
  #           expect(resp['error']).to eq('user_not_found')
  #         end
  #       end

  #       it 'Should fail im open api because invalid slack token' do
  #         slack_params = {
  #           'token' => 'abcd12 wert345 qsrt432',
  #           'user' => 'ABC123'
  #         }

  #         VCR.use_cassette 'failure_im_open_reason_invalid_slack_token' do
  #           response = Net::HTTP.post_form(
  #                         URI("https://slack.com/api/im.open"),
  #                         slack_params
  #                       )
  #           resp = JSON.parse(response.body)
  #           expect(resp['ok']).to eq(false)
  #           expect(resp['error']).to eq('invalid_auth')
  #         end
  #       end

  #       it 'Should fail im close api because invalid channel id' do
  #         slack_params = {
  #           'token' => SLACK_API_TOKEN,
  #           'channel' => 'DE12345'
  #         }

  #         VCR.use_cassette 'failure_im_close_reason_invlid_channel_id' do
  #           response = Net::HTTP.post_form(
  #                         URI("https://slack.com/api/im.close"),
  #                         slack_params
  #                       )
  #           resp = JSON.parse(response.body)
  #           expect(resp['ok']).to eq(false)
  #           expect(resp['error']).to eq('channel_not_found')
  #         end
  #       end

  #       it 'Should fail im close api because invalid slack token' do
  #         slack_params = {
  #           'token' => 'abcd12 wert345 qsrt432',
  #           'channel' => 'DE12345'
  #         }

  #         VCR.use_cassette 'failure_im_close_reason_invlid_slack_token' do
  #           response = Net::HTTP.post_form(
  #                         URI("https://slack.com/api/im.close"),
  #                         slack_params
  #                       )
  #           resp = JSON.parse(response.body)
  #           expect(resp['ok']).to eq(false)
  #           expect(resp['error']).to eq('invalid_auth')
  #         end
  #       end
  #     end
  #   end
  # end
  context 'Timesheet mail' do
    before do
      ActionMailer::Base.deliveries = []
    end
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project, start_date: Date.today - 5) }
    it 'should send mail if user is not assinged on project and filled timesheet' do
      time_sheet = FactoryGirl.create(:time_sheet, user: user, project: project, created_at: Date.today - 1)
      TimeSheet.get_users_and_timesheet_who_have_filled_timesheet_for_different_project
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'should not send mail if project is assigned to this user' do
      user_project = FactoryGirl.create(:user_project, user: user, project: project)
      timesheet    = FactoryGirl.create(:time_sheet, user: user, project: project)
    end
  end

  context "Employee's weekend work" do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:user_hr) { FactoryGirl.create(:user, role: 'HR', status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project, timesheet_mandatory: true) }
    
    before do
      ActionMailer::Base.deliveries = []
      @start_date = Date.today - 14
    end

    it 'send mail- when employee have filled timesheet on weekend' do
      FactoryGirl.create(:user_project, start_date: Date.today - 20,
                                        user: user,
                                        project: project)
      date = Date.today - Date.today.wday
      FactoryGirl.create(:time_sheet, date: date, user: user, project: project )
      TimeSheet.generate_and_send_weekend_report([date], @start_date)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq(
        "Weekend Timesheet Report (#{@start_date.strftime('%d %B')} - #{Date.today.strftime('%d %B')})"
      )
    end

    it 'send mail- when employee have filled timesheet on holiday' do
      FactoryGirl.create(:user_project, start_date: Date.today - 20,
                                        user: user,
                                        project: project)
      date = Date.today - 1
      FactoryGirl.build(:holiday, holiday_date: date, reason: 'Test')
      FactoryGirl.create(:time_sheet, date: date, user: user, project: project )
      TimeSheet.generate_and_send_weekend_report([date], @start_date)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq(
        "Weekend Timesheet Report (#{@start_date.strftime('%d %B')} - #{Date.today.strftime('%d %B')})"
      )
    end
  end
  
  context "Employees Working Hour Report" do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:user_hr) { FactoryGirl.create(:user, role: 'HR', status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project, timesheet_mandatory: true) }
    
    before do
      ActionMailer::Base.deliveries = []
      @dates = 7.days.ago.to_date..(Date.today - 1)
      @start_date = @dates.first
      @duration = 540
    end

    it 'send mail- when employee have worked more than 9 hours' do
      FactoryGirl.create(:user_project, start_date: Date.today - 20,
                                        user: user,
                                        project: project)
      date = Date.today - Date.today.wday
      FactoryGirl.create(:time_sheet, date: date,
                                      from_time: "#{Date.today - 1} 9:00",
                                      to_time: "#{Date.today - 1} 22:00",
                                      user: user,
                                      project: project )
      TimeSheet.generate_and_send_employees_working_hour_report(@dates, @duration)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq(
        "Employee Report - Worked More than 9 Hours During (#{@start_date.strftime('%d %B')} - #{(Date.today - 1).strftime('%d %B')})"
      )
    end

    it 'send mail- when employee have worked more than 9 hours on Weekend / Holiday' do
      FactoryGirl.create(:user_project, start_date: Date.today - 20,
                                        user: user,
                                        project: project)
      date = Date.today - 1
      FactoryGirl.build(:holiday, holiday_date: date, reason: 'Test')
      FactoryGirl.create(:time_sheet, date: date,
                                      from_time: "#{Date.today - 1} 9:00",
                                      to_time: "#{Date.today - 1} 22:00",
                                      user: user,
                                      project: project )
      TimeSheet.generate_and_send_employees_working_hour_report(@dates, @duration)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq(
        "Employee Report - Worked More than 9 Hours During (#{@start_date.strftime('%d %B')} - #{(Date.today - 1).strftime('%d %B')})"
      )
    end

    it 'do not send mail- when employee have worked less than 9 hours' do
      FactoryGirl.create(:user_project, start_date: Date.today - 20,
                                        user: user,
                                        project: project)
      date = Date.today - 1
      FactoryGirl.build(:holiday, holiday_date: date, reason: 'Test')
      FactoryGirl.create(:time_sheet, date: date,
                                      from_time: "#{Date.today - 1} 20:00",
                                      to_time: "#{Date.today - 1} 22:00",
                                      user: user,
                                      project: project )
      TimeSheet.generate_and_send_employees_working_hour_report(@dates, @duration)

      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
    
  end
  
  context "User without time_sheet" do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:userhr) { FactoryGirl.create(:user, role:"HR", status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project, :timesheet_mandatory => true) }
    before do
      ActionMailer::Base.deliveries = []
    end
    it "send mail- when user have not filled timesheet in particular period" do
      user_project = FactoryGirl.create(:user_project, :start_date => Date.today - 20,
       :user => user, :project => project)
      from_date = Date.today - 10
      to_date   = Date.today
      TimeSheet.get_users_who_not_filled_timesheet(from_date, to_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "Do not send mail if user are filling timesheet daily" do
      user_project = FactoryGirl.create(:user_project, :start_date => Date.today - 2,
       :user => user, :project => project)
      from_date = Date.today - 2
      to_date   = Date.today - 1
      FactoryGirl.create(:time_sheet, :date => Date.today - 2,
        :user => user, :project => project )
      FactoryGirl.create(:time_sheet, :date => Date.today - 1, :user => user,
       :project => project )
      TimeSheet.get_users_who_not_filled_timesheet(from_date, to_date)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it 'Do not send mail if employee is on leave' do
      user_project = FactoryGirl.create(:user_project, :start_date => Date.today - 3,
       :user => user, :project => project)
      FactoryGirl.create(:time_sheet, :date => Date.today - 3,
        :user => user, :project => project )
      leave = FactoryGirl.create(:leave_application, start_at: Date.today - 2, end_at: Date.today,
        user: user, leave_status: LEAVE_STATUS[1])
      from_date = Date.today - 3
      to_date   = Date.today
      TimeSheet.get_users_who_not_filled_timesheet(from_date, to_date)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it "Do not send mail if user is not assigned on any project" do
      from_date = Date.today - 2
      to_date   = Date.today
      TimeSheet.get_users_who_not_filled_timesheet(from_date, to_date)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it "Do not send mail if user projects timesheet mandatory false" do
      project      = FactoryGirl.create(:project, :timesheet_mandatory => false)
      user_project = FactoryGirl.create(:user_project, :start_date => Date.today - 2,
       :user => user, :project => project)
      from_date = Date.today - 2
      to_date   = Date.today
      TimeSheet.get_users_who_not_filled_timesheet(from_date, to_date)
      timesheet    = FactoryGirl.create(:time_sheet, user: user, project: project, date: Date.today - 1)
      TimeSheet.get_users_and_timesheet_who_have_filled_timesheet_for_different_project
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it "should not send mail if timesheet data empty" do
      TimeSheet.get_users_and_timesheet_who_have_filled_timesheet_for_different_project
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
  end
end
