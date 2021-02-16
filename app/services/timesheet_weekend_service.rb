class TimesheetWeekendService
  def initialize(from_date, to_date, email)
    @from_date = from_date.to_date
    @to_date = to_date.to_date
    @email = email
  end

  def call
    generate_timesheet_weekend_report
    ReportMailer.send_time_sheet_weekend_report(@reports, @email).deliver_now
  end

  def generate_timesheet_weekend_report
    @reports = []
    COUNTRIES.each do |country|
      report = {
        country_name: country,
        header: [],
        records: {}
      }
      report[:header] = fetch_weekend_and_holidays(country)
      records = {}
      report[:header].each do |date|
        records[:"#{date}"] = {}
        result = TimeSheet.get_users_and_total_worked_hours(date.to_date, 0)
        result.each do |r|
          user = User.where(id: r['_id']['user_id']).first
          next if user.country != country
          employee_id = user.employee_detail.try(:employee_id).try(:rjust, 3, '0')
          records[:"#{date}"][:"#{employee_id}"] = convert_duration_in_hours(r['total_duration'])
        end
      end
      record_struct = create_record_structure(report[:header])
      records.each do |date, v|
        v.each do |emp_id, duration|
          user_name = User.where(
            :'employee_detail.employee_id' => emp_id.to_s
          ).first.name
          report[:records][emp_id] =
            if !report[:records][emp_id]
              record_struct.merge({"#{date.to_s}": duration, user_name: user_name})
            else
              report[:records][emp_id].merge!({"#{date.to_s}": duration})
            end
        end
      end
      @reports << report
    end
    @reports
  end

  def create_record_structure(headers)
    records = {
      user_name: ''
    }
    headers.each do |h|
      records[:"#{h}"] = '-'
    end
    records
  end

  def convert_duration_in_hours(duration)
    hours, minutes = TimeSheet.calculate_hours_and_minutes(duration)
    hours > 0 ? "#{hours}h #{minutes}min" : "#{minutes}min"
  end

  def fetch_weekend_and_holidays(country)
    weekends_and_holidays = []
    (@from_date..@to_date).each do |date|
      weekends_and_holidays << date if HolidayList.is_holiday?(date.to_date, country)
    end
    weekends_and_holidays
  end
end
