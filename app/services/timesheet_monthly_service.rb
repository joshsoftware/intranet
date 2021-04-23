class TimesheetMonthlyService
  def initialize(from_date, to_date, email)
    @from_date = from_date.to_date
    @to_date = to_date.to_date
    @email = email
  end

  def call
    generate_timesheet_monthly_report
    ReportMailer.send_time_sheet_monthly_report(@reports, @email).deliver_now
  end

  def generate_timesheet_monthly_report
    @reports = []
    LOCATIONS.each do |location|
      report = {
        location_name: location,
        header: [],
        records: {},
        timesheet_per_day_count: {},
        holiday: [],
        resigned_emp_name: []
      }
      report[:header] = (@from_date..@to_date).to_a
      country = get_country_name(location)
      holiday = fetch_weekend_and_holidays(country)
      report[:holiday] = holiday
      records = {}
      result = {}
      timesheet_per_day_count = {}

      users = get_users_location_wise(location)
      all_users_id_set = users.pluck(:_id)
      initialize_users_records(users, report, records)
      report[:resigned_emp_name] = get_resigned_users_name(users)

      report[:header].each do |date|
        users_timesheet = TimeSheet.get_users_and_total_worked_hours(date.to_date, 0)
        user_result = {}
        filled_ts_users_id_set = []

        calculate_users_projects_and_total_duration(users, users_timesheet, all_users_id_set, filled_ts_users_id_set, user_result, date)
        on_leave_users_id_set = get_users_on_leave(date)
        filled_ts_users_id_set = all_users_id_set & filled_ts_users_id_set
        on_leave_users_id_set = all_users_id_set & on_leave_users_id_set

        is_optional_holiday = HolidayList.is_optional_holiday?(date)
        is_weekend = HolidayList.is_weekend?(date)
        is_holiday = holiday.include?(date)
        timesheet_per_day_count[:"#{date}"] = 0
        check_holiday_and_weekend = (!is_holiday || is_optional_holiday)
        str_date = date.strftime('%d/%m/%Y')

        # get common users list who are on leave and still worked.
        work_on_leave_users_id_set = filled_ts_users_id_set & on_leave_users_id_set

        # get the users list which is work on only weekday and weekend.
        work_on_weekday_and_weekend_users_id_set =  filled_ts_users_id_set - on_leave_users_id_set

        # get the users list which is worked but does not fill the timesheet.
        missing_ts_users_id_set = all_users_id_set - (filled_ts_users_id_set | on_leave_users_id_set)

        # get the users list who on leave.
        leave_on_users_id_set = on_leave_users_id_set - work_on_leave_users_id_set

        if check_holiday_and_weekend
          timesheet_missing_users(records, missing_ts_users_id_set, str_date)
        end

        if check_holiday_and_weekend
          users_on_leave(records, leave_on_users_id_set, str_date)
        end

        date_manipulations = {
          is_weekend: is_weekend,
          is_holiday: is_holiday,
          date: date,
          str_date: str_date,
          is_optional_holiday: is_optional_holiday
        }

        users_on_leave_and_still_worked(
          records,
          work_on_leave_users_id_set,
          user_result,
          timesheet_per_day_count,
          date_manipulations
        )

        users_worked_on_weekday_and_weekend(
          records,
          work_on_weekday_and_weekend_users_id_set,
          user_result,
          timesheet_per_day_count,
          date_manipulations
        )
      end
      report[:records] = records
      report[:timesheet_per_day_count] = timesheet_per_day_count
      @reports << report
    end
    @reports
  end

  def users_worked_on_weekday_and_weekend(records, work_on_weekday_and_weekend_users_id_set, user_result, timesheet_per_day_count, date_manipulations)
    work_on_weekday_and_weekend_users_id_set.uniq.each do |user_id|
      duration = user_result[user_id][:'duration']
      next if (date_manipulations[:is_optional_holiday] && duration < 540)

      if (date_manipulations[:is_holiday] || duration.to_i > 540)
        records[user_id][:'timesheet'][:"#{date_manipulations[:str_date]}"] = convert_duration_in_hours(duration)
        project_name = Project.where(:id => user_result[user_id][:'project_id']).first.try(:name)
        projects = records[user_id][:'project']

        if !projects.include?(project_name)
          records[user_id][:'project'] << project_name
        end

        if (date_manipulations[:is_holiday] && !date_manipulations[:is_weekend] && !date_manipulations[:is_optional_holiday])
          records[user_id][:"no_of_holiday"] += 1
        elsif date_manipulations[:is_weekend]
          records[user_id][:"no_of_weekend"] += 1
        else
          records[user_id][:"no_of_weekday"] += 1
        end
        timesheet_per_day_count[:"#{date_manipulations[:date]}"] += 1
        records[user_id][:'occurances'] += 1
      end
    end
  end

  def users_on_leave_and_still_worked(records, work_on_leave_users_id_set, user_result, timesheet_per_day_count, date_manipulations)
    work_on_leave_users_id_set.each do |user_id|
      total_duration = user_result[user_id][:'duration']
      if date_manipulations[:is_weekend]
        records[user_id][:'timesheet'][:"#{date_manipulations[:str_date]}"] = convert_duration_in_hours(total_duration)
        records[user_id][:'no_of_weekend'] += 1
      else
        records[user_id][:'timesheet'][:"#{date_manipulations[:str_date]}"] = 'LV + ' + convert_duration_in_hours(total_duration)
        records[user_id][:'no_of_holiday'] += 1
        records[user_id][:'no_of_leave_day'] += 1
      end
      records[user_id][:'occurances'] += 1
      timesheet_per_day_count[:"#{date_manipulations[:date]}"] += 1
    end
  end

  def calculate_users_projects_and_total_duration(users, users_timesheet, all_users_id_set, filled_ts_users_id_set, user_result, date)
    users_timesheet.each do |user_record|
      user_id = user_record['_id']['user_id']
      next if !all_users_id_set.include?(user_id)
      user = users.where(id: user_id).first
      filled_ts_users_id_set << user_id
      total_duration = TimeSheet.where(user: user, date: date).sum(:duration)
      user_result.merge!(user_id => {
        project_id: user_record['_id']['project_id'],
        duration: total_duration
      })
    end
  end

  def users_on_leave(records, leave_on_users_id_set, str_date)
    leave_on_users_id_set.each do |user_id|
      records[user_id][:'timesheet'][:"#{str_date}"] = 'LV'
      records[user_id][:'no_of_leave_day'] += 1
    end
  end

  def timesheet_missing_users(records, missing_ts_users_id_set, str_date)
    missing_ts_users_id_set.each do |user_id|
      records[user_id][:'timesheet'][:"#{str_date}"] = 'NF'
      records[user_id][:'no_of_ts_missing_days'] += 1
    end
  end

  def get_users_on_leave(date)
    LeaveApplication.leaves.where(
      :start_at.lte => date,
      :end_at.gte => date,
      leave_status: APPROVED
    ).pluck(:'user_id')
  end

  def initialize_users_records(users, report, records)
    users.each do |user|
      employee_id = user.employee_detail.try(:employee_id).try(:rjust, 3, '0')
      records.merge!(user.id => {
        employee_id: employee_id,
        user_name: user.name,
        project: [],
        occurances: 0,
        no_of_weekday: 0,
        no_of_weekend: 0,
        no_of_holiday: 0,
        no_of_ts_missing_days: 0,
        no_of_leave_day: 0,
        timesheet: {}
      })
      report[:header].each do |date|
        records[user.id][:'timesheet'][:"#{date}"] = ''
      end
    end
  end

  def get_resigned_users_name(users)
    users.where(
      status: STATUS[:resigned],
      'employee_detail.date_of_relieving': {
        '$gte': @from_date,
        '$lte': @to_date
      }
    ).collect(&:name)
  end

  def get_users_location_wise(location)
    User.where(
      'employee_detail.location': location,
      'private_profile.date_of_joining': {'$lte': @from_date}
    ).or(
      {status: STATUS[:approved]},
      {status: STATUS[:resigned],'employee_detail.date_of_relieving': {'$gte': @from_date}}
    ).order_by("public_profile.first_name" => :asc)
  end

  def convert_duration_in_hours(duration)
    hours, minutes = TimeSheet.calculate_hours_and_minutes(duration)
    hours > 0 ? "#{hours}.#{minutes}" : "0.#{minutes}"
  end

  def fetch_weekend_and_holidays(country)
    weekends_and_holidays = []
    (@from_date..@to_date).each do |date|
      weekends_and_holidays << date if HolidayList.is_holiday?(date.to_date, country)
    end
    weekends_and_holidays
  end

  def get_country_name(location)
    CityCountryMapping.each do |city_country|
      if location == city_country[:city]
        return city_country[:country]
      end
    end
  end

  def self.get_xlsx_column_index(column_number)
    dividend = column_number;
    column_index = ""
    modulo = 0
  
    while (dividend > 0)
      modulo = (dividend - 1) % 26
      column_index = (65 + modulo).chr + column_index
      dividend = ((dividend - modulo) / 26).to_i
    end
    column_index
  end
end
