namespace :leave_reminder do
  desc 'Reminds admin and HR who are on leave tomorrow.'
  task daily: :environment do
    country = COUNTRIES[:india]
    unless HolidayList.is_holiday?(Date.today, country)
      next_working_day = HolidayList.next_working_day(Date.today, country)
      leaves = LeaveApplication.get_leaves_for_sending_reminder(next_working_day)
      UserMailer.delay.leaves_reminder(leaves.to_a, 'Leave') if leaves.present?
    end
  end

  desc 'Reminds admin and HR who will be on leave for Optional Holiday.'
  task optional_holiday: :environment do
    tomorrow = Date.tomorrow
    if HolidayList.is_optional_holiday?(tomorrow)
      leaves = LeaveApplication.get_optional_holiday_request(tomorrow)
      UserMailer.delay.leaves_reminder(leaves.to_a, 'Optional Holiday') if leaves.present?
    end
  end

  desc 'Reminds admin and HR who will be on leave next month for Optional Holiday.'
  task optional_holiday_reminder_next_month: :environment do
    date = Date.today.at_end_of_month + 1
    leaves = LeaveApplication.where(
      leave_status: LEAVE_STATUS[:approved],
      leave_type: LeaveApplication::OPTIONAL,
      start_at: {
        '$gte': date,
        '$lte': date.at_end_of_month
      }
    )
    UserMailer.delay.optional_holiday_reminder_next_month(leaves.to_a, date) if leaves.present?
  end

  desc 'Reminds managers and HR whose leave beginning in next two days and leave is pending.'
  task :pending_leave => :environment do
    country = COUNTRIES[:india]
    unless HolidayList.is_holiday?(Date.today, country)
      LeaveApplication.pending_leaves_reminder(country)
    end
  end
end
