class TimeSheet
  include Mongoid::Document
  include Mongoid::Timestamps
  extend CheckUser

  field :user_id
  field :project_id
  field :date,            :type => Date
  field :from_time,       :type => Time
  field :to_time,         :type => Time
  field :duration,        :type => Integer
  field :description,     :type => String
  field :created_by,      :type => String
  field :updated_by,      :type => String

  belongs_to :user
  belongs_to :project

  validates :project_id, :date, :description, presence: true
  validate :is_future_date?
  before_validation :valid_date_for_create?, unless: :is_management?
  validates_uniqueness_of :project_id, scope: [:date, :user_id], message: 'Cannot add multiple timesheets for same project'
  validates :from_time, :to_time, uniqueness: { scope: [:user_id, :date], message: "Record already present" }, if: :is_from_time_and_to_time_present?
  # when both of them are absent thats when we have to check for the duration
  validates :duration, presence: true, unless: :is_from_time_or_to_time_present?
  # when atleast one of those is present thats when check for others presence
  validate :presence_of_from_time_and_to_time?, if: :is_from_time_or_to_time_present?
  validate :from_time_is_future_time?, :to_time_is_future_time?, :time_sheet_overlapping?, if: :is_from_time_and_to_time_present?
  validate :working_hours_less_than_max_threshold
  # validate :timesheet_date_greater_than_project_start_date, if: :is_project_assigned_to_user?

  DURATION_HASH = {
    30 => '30 mins', 60 => '1 hour', 90 => '1 hour 30 mins',
    120 => '2 hours', 150 => '2 hours 30 mins', 180 => '3 hours',
    210 => '3 hours 30 mins', 240 => '4 hours', 270 => '4 hours 30 mins',
    300 => '5 hours', 330 => '5 hours 30 mins', 360 => '6 hours',
    390 => '6 hours 30 mins', 420 => '7 hours',
    450 => '7 hours 30 mins', 480 => '8 hours',
    540 => '9 hours', 600 => '9 hours',
    660 => '11 hours', 720 => '12 hours'
  }
  MAX_TIMESHEET_COMMAND_LENGTH = 5
  DATE_FORMAT_LENGTH = 3
  MAX_DAILY_STATUS_COMMAND_LENGTH = 2
  ALLOCATED_HOURS = 8
  DAYS_FOR_UPDATE = 7
  # change it back after running rake task to calculate duration
  DAYS_FOR_CREATE = Date.today - TimeSheet.first.date
  # threshold pending days after which mail will be sent to all receivers
  PENDING_THRESHOLD = 3
  # Working hours threshold for a day
  WORKING_HOURS_THRESHOLD = 24

  def is_from_time_and_to_time_present?
    from_time.present? and to_time.present?
  end

  def is_from_time_or_to_time_present?
    from_time.present? or to_time.present?
  end

  def presence_of_from_time_and_to_time?
    text = "can't be blank"
    unless to_time.present?
      errors.add(:to_time, text)
    end
    unless from_time.present?
      errors.add(:from_time, text)
    end
  end

  # this method is used to check if total worked hours for a day is within limit
  def working_hours_less_than_max_threshold
    total_duration = TimeSheet.where(user: user, date: date).sum(:duration)
    # here to_i is used as calculate_working_minutes for time-range return float which causes issues
    self.duration = TimeSheet.calculate_working_minutes(self).to_i
    total_duration += duration
    # for update purpose if record persists deduct previous duration
    # duration_was in condition if previous duration is nil
    total_duration -= duration_was if persisted? and duration_was and date_was == date
    total_hours_worked = TimeSheet.total_worked_in_hours(total_duration)
    if total_hours_worked > WORKING_HOURS_THRESHOLD
      errors.add(:duration, "total working hours can't exceed #{WORKING_HOURS_THRESHOLD} hours")
    end
  end

  def parse_timesheet_data(params)
    split_text = params['text'].split

    return false unless valid_command_format?(split_text, params['channel_id'])
    return false unless valid_project_name?(split_text[0], params)
    return false unless valid_date_format?(split_text[1], params)
    return false unless time_validation(split_text[1], split_text[2], split_text[3], params)

    time_sheets_data = time_sheets(split_text, params)
    return true, time_sheets_data
  end

  def valid_command_format?(split_text, channel_id)
    if split_text.length < MAX_TIMESHEET_COMMAND_LENGTH
      text = "\`Error :: Invalid timesheet format. Format should be <project_name> <date> <from_time> <to_time> <description>\`"
      SlackApiService.new.post_message_to_slack(channel_id, text)
      return false
    end
    return true
  end

  def valid_project_name?(project_name, params)
    user = User.where("public_profile.slack_handle" => params['user_id'])
    project = user.first.projects.find_by(display_name: /^#{project_name}$/i) rescue nil
    return true if !project.nil? || project_name == 'other'
    text = "\`Error :: You are not working on this project. Use /projects command to view your project\`"
    SlackApiService.new.post_message_to_slack(params['channel_id'], text)
    return false
  end

  def valid_date_format?(date, params)
    split_date = date.include?('/')? date.split('/') : date.split('-')

    if split_date.length < DATE_FORMAT_LENGTH
      text = "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end

    valid_date?(split_date, date, params)
  end

  def valid_date?(split_date, date, params)
    valid_date = Date.valid_date?(split_date[2].to_i, split_date[1].to_i, split_date[0].to_i)
    unless valid_date
      SlackApiService.new.post_message_to_slack(params['channel_id'], "\`Error :: Invalid date\`")
      return false
    end
    return true if params['command'] == '/daily_status'
    return true
  end

  # def timesheet_date_greater_than_project_start_date
  #   if timesheet_date_greater_than_assign_project_date
  #     text = "Not allowed to fill timesheet for this date. As you were not assigned on project for this date"
  #     errors.add(:date, text)
  #     return false
  #   end
  #   return true
  # end

  # def timesheet_date_greater_than_assign_project_date
  #   user = User.find(self.user_id)
  #   user_project = UserProject.find_by(user_id: user.id, project_id: project_id, end_date: nil)
  #     if date < user_project.start_date
  #       return true
  #     end
  #   return false
  # end

  def is_project_assigned_to_user?
    UserProject.where(user_id: user.id, project_id: project_id).exists?
  end

  def valid_date_for_update?
    date > Date.today - DAYS_FOR_UPDATE
  end

  def is_management?
    TIMESHEET_MANAGEMENT.include?(User.find(created_by).role) if created_by.present?
  end

  def valid_date_for_create?
    return false if errors.full_messages.present?
    if date.blank?
      errors.add(:date, 'Invalid time')
      return false
    end
    if date < Date.today - DAYS_FOR_CREATE
      text = "Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager."
      errors.add(:date, text)
      return false
    end
    return true
  end

  def from_time_is_future_time?
    if from_time >= Time.now
      text = "Can't fill the timesheet for future time."
      errors.add(:from_time, text)
      return false
    elsif from_time >= to_time
       text = "From time must be less than to time"
       errors.add(:from_time, text)
       return false
    end
    return true
  end

  def to_time_is_future_time?
    if to_time > Time.now
      text = "Can't fill the timesheet for future time."
      errors.add(:to_time, text)
      return false
    end
    return false
  end

  def is_future_date?
    if date > Date.today
      text = "Can't fill the timesheet for future date."
      errors.add(:date, text)
      return false
    end
    return true
  end

  def time_validation(date, from_time, to_time, params)
    from_time = valid_time?(date, from_time, params, :from_time)
    return false unless from_time
    to_time = valid_time?(date, to_time, params, :to_time)
    return false unless to_time
    return true
  end

  def valid_time?(date, time, params, attribute)
    time_format = check_time_format(time)
    if time_format
      return_value = Time.parse(date + ' ' + time_format) rescue nil
    end

    unless return_value
      text = "\`Error :: Invalid time format. Format should be HH:MM\`"
      text_for_ui = "Invalid time format. Format should be HH:MM"
      errors.add(attribute, text_for_ui) if params == 'from_ui'
      SlackApiService.new.post_message_to_slack(params['channel_id'], text) unless params == 'from_ui'
      return false
    end
    return_value
  end

  def self.formatted_duration(total_minute)
    hours = total_minute / 60
    minutes = (total_minute) % 60
    "#{ hours }h #{ minutes }min"
  end

  def check_time_format(time)
    return false if time.to_s.include?('.')
    return time + (':00') unless time.to_s.include?(':')
    time
  end

  def concat_description(split_text)
    description = ''
    split_text[4..-1].each do |string|
      description = description + string + ' '
    end
    description
  end

  def time_sheet_overlapping?
    return_value = true
    TimeSheet.where(date: date, user_id: user_id).order("from_time ASC").each do |time_sheet|
      next if time_sheet == self
      next unless time_sheet.is_from_time_and_to_time_present?
      if time_sheet.from_time < from_time && time_sheet.to_time > to_time ||
       time_sheet.from_time > from_time && time_sheet.to_time < to_time ||
       time_sheet.from_time > from_time && time_sheet.to_time > to_time && time_sheet.from_time < to_time ||
       time_sheet.from_time < from_time && time_sheet.to_time < to_time && time_sheet.to_time > from_time
        errors.add(:from_time, "Time duration is overlapping with already entered time duration for the day")
        errors.add(:to_time, "Time duration is overlapping with already entered time duration for the day")
        return_value = false
        break
      end
    end
    return_value
  end

  def time_sheets(split_text, params)
    time_sheets_data = {}
    user = User.where("public_profile.slack_handle" => params['user_id'])
    project = load_project(user, split_text[0])
    time_sheets_data['user_id'] = user.first.id
    time_sheets_data['project_id'] = project.nil? ? nil : project.id
    time_sheets_data['date'] = Date.parse(split_text[1])
    time_sheets_data['from_time'] = Time.parse(split_text[1] + ' ' + split_text[2])
    time_sheets_data['to_time'] = Time.parse(split_text[1] + ' ' + split_text[3])
    time_sheets_data['description'] = concat_description(split_text)
    time_sheets_data
  end

  def self.parse_daily_status_command(params)
    split_text = params['text'].split
    if split_text.length < MAX_DAILY_STATUS_COMMAND_LENGTH
      time_sheet_log = get_time_sheet_log(params, params['text'])
    else
      text = "\`Error :: Invalid command options. Use /daily_status <date> to view your timesheet log\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
    end
    time_sheet_log.present? ? time_sheet_log : false
  end

  def self.get_time_sheet_log(params, date)
    text = 'You have not filled timesheet for'
    text = date.present? ? "\`#{text} #{date}.\`" : "\`#{text} today.\`"
    if date.present?
      return false unless TimeSheet.new.valid_date_format?(date, params)
    end
    user = load_user(params['user_id'])
    time_sheets, time_sheet_message =
    date.present? ? load_time_sheets(user, Date.parse(date)) : load_time_sheets(user, Date.today.to_s)
    return false unless time_sheet_present?(time_sheets, params, text)
    time_sheet_log = prepend_index(time_sheets)
    time_sheet_message + ". Details are as follow\n\n" + time_sheet_log
  end

  def self.time_sheet_present?(time_sheets, params, text)
    unless time_sheets.present?
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def self.prepend_index(time_sheets)
    time_sheet_log = time_sheets.each_with_index.map{|time_sheet, index| time_sheet.join(' ').prepend("#{index + 1}. ") + " \n"}
    time_sheet_log.join('')
  end

  def self.search_user_and_send_reminder(users)
    users.each do |user|
      next if user.projects.where(timesheet_mandatory: true).count.eql?(0)
      next if user.user_projects.or(
        {end_date: nil}, {:end_date.gt => Date.today}).where(time_sheet: true).count == 0

      last_filled_time_sheet_date = user.time_sheets.order(date: :asc).last.date + 1 if time_sheet_present_for_reminder?(user)
      next if last_filled_time_sheet_date.nil?
      date_difference = calculate_date_difference(last_filled_time_sheet_date)
      if date_difference < 2 && last_filled_time_sheet_date < Date.today
        next if HolidayList.is_holiday?(last_filled_time_sheet_date)
        unless user_on_leave?(user, last_filled_time_sheet_date)
          unfilled_timesheet = last_filled_time_sheet_date unless time_sheet_filled?(user, last_filled_time_sheet_date)
        end
      else
        while(last_filled_time_sheet_date < Date.today)
          next last_filled_time_sheet_date += 1 if HolidayList.is_holiday?(last_filled_time_sheet_date)
          unless user_on_leave?(user, last_filled_time_sheet_date)
            unfilled_timesheet = last_filled_time_sheet_date unless time_sheet_filled?(user, last_filled_time_sheet_date)
            break
          end
          last_filled_time_sheet_date += 1
        end
      end
      unfilled_timesheet_present?(user, unfilled_timesheet)
    end
  end

  def self.load_time_sheets(user, date)
    time_sheet_log = []
    total_minutes = 0
    time_sheet_message = 'You worked on'
    user.first.worked_on_projects(date, date).includes(:time_sheets).each do |project|
      project.time_sheets.where(user_id: user.first.id, date: date).each do |time_sheet|
        time_sheet_data = []
        from_time = time_sheet.from_time.strftime("%I:%M%p")
        to_time = time_sheet.to_time.strftime("%I:%M%p")
        time_sheet_data.push(project.name, from_time, to_time, time_sheet.description)
        time_sheet_log << time_sheet_data
        minutes = calculate_working_minutes(time_sheet)
        total_minutes += minutes
        time_sheet_data = []
      end
      hours, minutes = calculate_hours_and_minutes(total_minutes.to_i)
      next if hours == 0 && minutes == 0
      time_sheet_message += " *#{project.name}: #{hours}H #{minutes}M*"
      total_minutes = 0
    end
    return time_sheet_log, time_sheet_message
  end

  def self.generate_employee_timesheet_report(timesheets, from_date, to_date, current_user)
    timesheet_reports = []
    timesheets.each do |timesheet|
      user = load_user_with_id(timesheet['_id'])
      users_timesheet_data              = {}
      users_timesheet_data['user_name'] = user.name
      users_timesheet_data['user_id']   = user.id
      project_details = []
      total_work      = 0
      timesheet['working_status'].each do |working_status|
        project_info = {}
        project_info['project_name'] = get_project_name(working_status['project_id'])
        worked_hours = convert_milliseconds_to_hours(working_status['total_time'])
        project_info['worked_hours'] = convert_hours_to_days(worked_hours)
        total_work += working_status['total_time']
        project_details << project_info
        users_timesheet_data['project_details'] = project_details
      end
      total_worked_hours = convert_milliseconds_to_hours(total_work)
      users_timesheet_data['total_worked_hours'] = convert_hours_to_days(total_worked_hours)
      users_timesheet_data['leaves'] = approved_leaves_count(user, from_date, to_date)
      timesheet_reports << users_timesheet_data
    end
    users_without_timesheet = get_users_without_timesheet(from_date, to_date, current_user)
    return sort_on_user_name_and_project_name(timesheet_reports), users_without_timesheet
  end

  def self.create_projects_report_in_json_format(projects_report, from_date, to_date)
    projects_report_in_json = []
    project_names = []
    user_ids = []
    projects_report.each do |project_report|
      project_details = {}
      project = load_project_with_id(project_report['_id']['project_id'])
      project_names << project.name
      project_details['project_id'] = project.id
      project_details['project_name'] = project.name
      project_details['no_of_employee'] = project.get_user_projects_from_project(from_date, to_date).count
      total_hours = convert_milliseconds_to_hours(project_report['totalSum'])
      project_details['total_hours'] = convert_hours_to_days(total_hours)
      project_details['allocated_hours'] = get_allocated_hours(project, from_date, to_date)
      project_details['leaves'] = get_leaves(project, from_date, to_date)
      projects_report_in_json << project_details
      project_details = {}
    end
    projects_report_in_json.sort!{|previous_record, next_record| previous_record['project_name'] <=> next_record['project_name']}
    project_without_timesheet = get_project_without_timesheet(project_names, from_date, to_date) if project_names.present?
    return projects_report_in_json, project_without_timesheet
  end

  def self.generate_individual_timesheet_report(user, params, convert_hrs = true)
    time_sheet_log = []
    individual_time_sheet_data = {}
    total_minutes = 0
    total_minutes_worked_on_projects = 0
    user.worked_on_projects(params[:from_date], params[:to_date]).includes(:time_sheets).each do |project|
      project.time_sheets.where(user_id: user.id, date: {"$gte" => params[:from_date], "$lte" => params[:to_date]}).order_by(date: :asc).each do |time_sheet|
        time_sheet_data = []
        from_time, to_time = format_time(time_sheet)
        working_minutes    = calculate_working_minutes(time_sheet)
        hours, minutes     = calculate_hours_and_minutes(working_minutes.to_i)
        time_sheet_record  = create_time_sheet_record(time_sheet, from_time, to_time, "#{hours}:#{minutes}")
        time_sheet_data    << time_sheet_record
        time_sheet_log     << time_sheet_data
        total_minutes      += working_minutes
        total_minutes_worked_on_projects += working_minutes
        time_sheet_data = []
      end
      working_details = {}
      total_worked_hours =
        convert_hrs ?
        convert_hours_to_days(total_worked_in_hours(total_minutes.to_i)) :
        total_worked_in_hours(total_minutes.to_i)
      working_details['daily_status'] = time_sheet_log
      working_details['total_worked_hours'] = total_worked_hours
      individual_time_sheet_data["#{project.name}"] = working_details
      time_sheet_log  = []
      working_details = {}
      total_minutes   = 0
    end
    total_work_and_leaves = get_total_work_and_leaves(user, params, total_minutes_worked_on_projects.to_i, convert_hrs)
    return individual_time_sheet_data, total_work_and_leaves
  end


  def self.generate_individual_project_report(project, params, convert_hrs = true)
    individual_project_report = {}
    total_minutes = 0
    total_minutes_worked_on_projects = 0
    project.get_user_projects_from_project(params[:from_date], params[:to_date]).includes(:time_sheets).each do |user|
      report_details = {}
      time_sheet_log = []
      user.time_sheets.where(project_id: project.id, date: {"$gte" => params[:from_date], "$lte" => params[:to_date]}).order_by(date: :asc).each do |time_sheet|
        working_minutes = calculate_working_minutes(time_sheet)
        total_minutes += working_minutes
        total_minutes_worked_on_projects += working_minutes
      end
      user_projects = user.get_user_projects_from_user(project.id, params[:from_date].to_date, params[:to_date].to_date)
      allocated_hours = total_allocated_hours(user_projects, params[:from_date].to_date, params[:to_date].to_date)
      leaves_count = total_leaves_count(user, user_projects, params[:from_date].to_date, params[:to_date].to_date)
      report_details['total_work'] = convert_hrs ?
        convert_hours_to_days(total_worked_in_hours(total_minutes.to_i)) :
        total_worked_in_hours(total_minutes.to_i)
      report_details['allocated_hours'] = convert_hours_to_days(allocated_hours)
      report_details['leaves'] = leaves_count
      time_sheet_log << report_details
      individual_project_report["#{user.name}"] = time_sheet_log
      total_minutes = 0
    end
    project_report = get_total_work_and_leaves_for_project_report(project, params, total_minutes_worked_on_projects, convert_hrs)
    return individual_project_report, project_report
  end

  def self.get_project_and_generate_weekly_report(managers, from_date, to_date)
    managers.each do |manager|
      unfilled_time_sheet_report = []
      weekly_report = []
      manager.managed_projects.each do |project|
        total_minutes = 0
        project.get_user_projects_from_project(from_date, to_date).includes(:time_sheets).each do |user|
          time_sheet_log = []
          minutes, users_without_timesheet = get_time_sheet_and_calculate_total_minutes(user, project, from_date, to_date)
          total_minutes += minutes
          unfilled_time_sheet_report << users_without_timesheet if users_without_timesheet.present?
          user_projects = user.get_user_projects_from_user(project.id, from_date.to_date, to_date.to_date)
          total_days_work = convert_hours_to_days(total_worked_in_hours(total_minutes.to_i))
          leaves_count = total_leaves_count(user, user_projects, from_date, to_date)
          holidays_count = get_holiday_count(from_date, to_date)
          if total_minutes != 0
            time_sheet_log.push(user.name, project.name, total_days_work, leaves_count, holidays_count)
            weekly_report << time_sheet_log
          end
          total_minutes = 0
        end
      end
      send_report_through_mail(weekly_report, manager.email, unfilled_time_sheet_report) if weekly_report.present?
    end
  end

  def self.generate_and_send_weekend_report(holiday_list, start_date)
    weekend_report = []
    holiday_list.each do |date|
      project_ids = TimeSheet.where(date: date).map(&:project_id).uniq
      project_ids.each do |project|
        users = TimeSheet.where(date: date, project_id: project)
                         .order(:start_time.asc)
                         .map(&:user_id).uniq
        users.each do |user|
          timesheets = TimeSheet.where(date: date, project_id: project, user_id: user)
          weekend_report += timesheets.map { |i| [ i.project.name,
                                                   i.user.name,
                                                   i.date.to_s,
                                                   formatted_duration(i.duration),
                                                   i.description] }
        end 
      end
    end
    if weekend_report.present?
      headers = ['Project Name', 'Employee Name', 'Date', 'Duration', 'Description']
      csv = generate_report_in_csv_format(headers, weekend_report)
      WeeklyTimesheetReportMailer.send_weekend_timesheet_report(csv, start_date).deliver_now!
    end
  end

  def self.generate_and_send_employees_working_hour_report(dates, duration)
    reports = []
    dates.each do |date|
      result = TimeSheet.get_users_and_total_worked_hours(date, duration)
      if result.present?
        users = result.map { |i| i[:_id][:user_id] }
        users.each do |user|
          timesheets = TimeSheet.where(date: date, user_id: user).group_by(&:project_id)
          timesheets.keys.each do |key|
            total_duration = timesheets[key].map(&:duration).sum
            reports << [  timesheets[key].first.date.to_s,
                          timesheets[key].first.user.name,
                          timesheets[key].first.project.name,
                          formatted_duration(total_duration)]
          end
        end
      end
    end

    if reports.present?
      headers = ['Date', 'Employee Name', 'Project Name', 'Total time spent']
      csv = generate_report_in_csv_format(headers, reports)
      WeeklyTimesheetReportMailer.send_employees_working_hour_report(csv, dates.first).deliver_now!  
    end
  end

  def self.get_time_sheet_and_calculate_total_minutes(user, project, from_date, to_date)
    users_without_timesheet = []
    total_minutes = 0
    user_projects = user.get_user_projects_from_user(project.id, from_date.to_date, to_date.to_date)
    leaves_count = total_leaves_count(user, user_projects, from_date, to_date)
    time_sheets = get_time_sheet_between_range(user, project.id, from_date, to_date)
    if !time_sheets.present? && !project.timesheet_mandatory == false &&
       (user.role == ROLE[:employee] || user.role == ROLE[:intern])
         users_without_timesheet.push(user.name, project.name, leaves_count)
    end
    time_sheets.each do |time_sheet|
      working_minutes = calculate_working_minutes(time_sheet)
      total_minutes += working_minutes
    end
    return total_minutes, users_without_timesheet
  end

  def self.create_time_sheet_record(time_sheet, from_time, to_time, total_worked)
    time_sheet_record = {}
    time_sheet_record['id'] = time_sheet.id
    time_sheet_record['date'] = time_sheet.date
    time_sheet_record['from_time'] = from_time
    time_sheet_record['to_time'] = to_time
    time_sheet_record['total_worked'] = total_worked
    time_sheet_record['description'] = time_sheet.description
    time_sheet_record
  end

  def self.create_project_timesheet_report(project, from_date, to_date)
    time_sheet_details = {}
    time_sheet_log     = []
    time_sheet_records = load_time_sheet_and_calculate_total_work(project.id, from_date, to_date)
    time_sheet_records.each do |time_sheet_record|
      user = User.find(time_sheet_record["_id"].to_s)
      time_sheet_record['working_status'].each do |record|
        time_sheet_data = {}
        total_hours     = convert_milliseconds_to_hours(record['total_time'])
        description     = load_time_sheet_and_get_description(user, project, record['date'])
        time_sheet_data = {
          user_name: user.name,
          date: record['date'].strftime('%d-%m-%Y'),
          total_hours: total_hours,
          description: description
        }
        time_sheet_log << time_sheet_data
      end
    end
    time_sheet_log.sort!{|previous_record, next_record| previous_record[0] <=> next_record[0]}
    time_sheet_log
  end

  def self.create_all_projects_employees_timesheet_summary(from_date, to_date)
    timesheet_summary = []
    Project.all_active.each do|project|
      time_sheet_records = load_time_sheet_and_calculate_total_work(project.id, from_date, to_date)
      time_sheet_records.each do |time_sheet_record|
        total_hours     = 0
        time_sheet_data = {}
        user            = User.find(time_sheet_record["_id"].to_s)
        time_sheet_record['working_status'].each do |record|
          total_hrs    = convert_milliseconds_to_hours(record['total_time'])
          total_hours += total_hrs
        end
        time_sheet_data = {
          project_name: project.name,
          emp_id: user.employee_detail.employee_id,
          user_name: user.name,
          total_work_days: total_hours
        }
        timesheet_summary << time_sheet_data
      end
    end
    timesheet_summary
  end

  def self.create_all_projects_summary(from_date, to_date)
    timesheet_summary = []
    params            = { from_date: from_date, to_date: to_date }
    Project.all_active.each do |project|
      timesheet_data = {}
      @individual_project_report, @project_report =
        generate_individual_project_report(project, params, false)
      timesheet_data = {
        project_name: project.name,
        total_hours: @project_report['total_worked_hours']
      }
      timesheet_summary << timesheet_data
    end
    timesheet_summary
  end

  def self.create_all_employee_summary(from_date, to_date)
    params            = {from_date: from_date, to_date: to_date}
    timesheet_summary = []
    User.approved.employees.each do | user |
      timesheet_data = {}
      @individual_time_sheet_data, @total_work_and_leaves =
        generate_individual_timesheet_report(user, params, false)
      timesheet_data = {
        emp_id: user.employee_detail.employee_id,
        user_name: user.name,
        total_worked_hours: @total_work_and_leaves['total_work']
      }
      timesheet_summary << timesheet_data
    end
    timesheet_summary
  end

  def self.load_time_sheet_and_get_description(user, project, date)
    TimeSheet.where(user_id: user.id, project_id: project.id, date: date).collect(&:description).join("\n")
  end

  def self.format_time(time_sheet)
    from_time, to_time = "N.A.", "N.A."
    unless time_sheet.from_time.blank? or time_sheet.to_time.blank?
      from_time = time_sheet.from_time.strftime("%I:%M%p")
      to_time = time_sheet.to_time.strftime("%I:%M%p")
    end
    return from_time, to_time
  end

  def self.get_total_work_and_leaves_for_project_report(project, params, total_minutes_worked_on_projects, convert_hrs)
    project_report = {}
    total_hours_worked_on_project =
      convert_hrs ?
      convert_hours_to_days(total_worked_in_hours(total_minutes_worked_on_projects.to_i)) :
      total_worked_in_hours(total_minutes_worked_on_projects.to_i)
    total_allocated_hours_on_projects = get_allocated_hours(project, params[:from_date].to_date, params[:to_date].to_date)
    total_leaves = get_leaves(project, params[:from_date].to_date, params[:to_date].to_date)
    project_report['total_worked_hours'] = total_hours_worked_on_project
    project_report['total_allocated_hourse'] = total_allocated_hours_on_projects
    project_report['total_leaves'] = total_leaves
    project_report
  end

  def self.get_total_work_and_leaves(user, params, total_minutes_worked_on_projects, convert_hrs)
    total_work_and_leaves = {}
    total_worked_hours = total_worked_in_hours(total_minutes_worked_on_projects.to_i)
    total_work_and_leaves['total_work'] =
      convert_hrs ? convert_hours_to_days(total_worked_hours) : total_worked_hours
    total_work_and_leaves['leaves'] = approved_leaves_count(user, params[:from_date], params[:to_date])
    total_work_and_leaves
  end

  def self.send_report_through_mail(weekly_report, email, unfilled_time_sheet_report)
    headers = ['Employee name', 'Project name', 'No of days worked', 'Leaves', 'Holidays'] 
    csv = generate_report_in_csv_format(headers, weekly_report)
    WeeklyTimesheetReportMailer.send_weekly_timesheet_report(csv, email, unfilled_time_sheet_report).deliver_now!
  end

  def self.calculate_working_minutes(time_sheet)
    unless time_sheet.from_time.blank? or time_sheet.to_time.blank?
      return TimeDifference.between(time_sheet.to_time, time_sheet.from_time).in_minutes
    end
    return time_sheet.duration
  end

  def self.get_allocated_hours(project, from_date, to_date)
    total_allocated_hours = 0
    project.get_user_projects_from_project(from_date, to_date).each do |user|
      user_projects = user.get_user_projects_from_user(project.id, from_date, to_date)
      allocated_hours = total_allocated_hours(user_projects, from_date, to_date)
      total_allocated_hours += allocated_hours
    end
    convert_hours_to_days(total_allocated_hours)
  end

  def self.get_working_days(from_date, to_date)
    working_days = from_date.business_days_until(to_date)
    no_of_holiday = get_holiday_count(from_date, to_date)
    working_days -= no_of_holiday
  end

  def self.get_leaves(project, from_date, to_date)
    total_leaves_count = 0
    project.get_user_projects_from_project(from_date, to_date).each do |user|
      user_projects = user.get_user_projects_from_user(project.id, from_date, to_date)
      leaves_count = total_leaves_count(user, user_projects, from_date, to_date)
      total_leaves_count += leaves_count
    end
    total_leaves_count
  end

  def self.total_allocated_hours(user_projects, from_date, to_date)
    total_allocated_hours = 0
    user_projects.each do |user_project|
      working_days =
        if user_project.end_date.present?
          if from_date <= user_project.start_date
            get_working_days(user_project.start_date, user_project.end_date)
          elsif from_date > user_project.start_date
            get_working_days(from_date, user_project.end_date)
          end
        else
          if from_date <= user_project.start_date
            get_working_days(user_project.start_date, to_date)
          elsif from_date > user_project.start_date
            get_working_days(from_date, to_date)
          end
        end
      allocated_hours = working_days * ALLOCATED_HOURS
      total_allocated_hours += allocated_hours
    end
    total_allocated_hours
  end

  def self.total_leaves_count(user, user_projects, from_date, to_date)
    total_leaves_count = 0
    user_projects.each do |user_project|
      leaves_count =
        if user_project.end_date.present?
          if from_date <= user_project.start_date
            approved_leaves_count(user, user_project.start_date, user_project.end_date)
          elsif from_date > user_project.start_date
            approved_leaves_count(user, from_date, user_project.end_date)
          end
        else
          if from_date <= user_project.start_date
            approved_leaves_count(user, user_project.start_date, to_date)
          elsif from_date > user_project.start_date
            approved_leaves_count(user, from_date, to_date)
          end
        end
      total_leaves_count += leaves_count
    end
    total_leaves_count
  end

  def self.generate_report_in_csv_format(headers, reports)
    report_in_csv =
      CSV.generate(headers: true) do |csv|
        csv << headers
        reports.each do |report|
          csv << report
        end
      end
    report_in_csv
  end

  def self.sort_on_user_name_and_project_name(timesheet_reports)
    sort_on_user_name =
      timesheet_reports.sort{|previous_record, next_record| previous_record['user_name'] <=> next_record['user_name']}

    sort_on_project_name =
      sort_on_user_name.each do |report|
        report['project_details'].sort!{|previous_record, next_record| previous_record['project_name'] <=> next_record['project_name']}
      end

    sort_on_project_name
  end

  def self.unfilled_time_sheet_for_last_week(user)
    users_without_timesheet = []
    users_without_timesheet << user.name unless users_without_timesheet.include?(user.name)
    users_without_timesheet
  end

  def self.calculate_hours_and_minutes(total_minutes)
    hours, minutes = convert_minutes_into_hours(total_minutes)
    minutes = '%02i'%minutes
    return hours, minutes
  end

  def self.convert_minutes_into_hours(total_minutes)
    hours = total_minutes / 60
    minutes = total_minutes % 60
    return hours, minutes
  end

  def self.total_worked_in_hours(total_minutes)
    hours, minutes = convert_minutes_into_hours(total_minutes)
    hours = minutes < 30 ? hours : hours + 1
    hours
  end

  def self.convert_milliseconds_to_hours(milliseconds)
    hours = milliseconds / (1000 * 60 * 60)
    minutes = milliseconds / (1000 * 60) % 60
    hours = minutes < 30 ? hours : hours + 1
    hours
  end

  def self.convert_hours_to_days(total_allocated_hourse)
    days = hours = 0
    days = total_allocated_hourse / ALLOCATED_HOURS
    hours = total_allocated_hourse % ALLOCATED_HOURS
    result = hours > 0 ? "#{days} Days #{hours}h (#{total_allocated_hourse}h)" : "#{days} Days (#{total_allocated_hourse}h)"
    result
  end

  def self.get_project_without_timesheet(project_names, from_date, to_date)
    unfilled_timesheet_projects = []
    projects = Project.not_in(name: project_names)
    projects.where("$or" => [{end_date: nil}, {end_date: {"$gte" => from_date, "$lte" => to_date}}]).each do |project|
      project_detail = {}
      project_detail['project_id'] = project.id
      project_detail['project_name'] = project.name
      unfilled_timesheet_projects << project_detail
    end
    unfilled_timesheet_projects.sort{|previous_record, next_record| previous_record['project_name'] <=> next_record['project_name']}
  end

  def self.get_users_without_timesheet(from_date, to_date, current_user)
    return if current_user.role == ROLE[:employee] || current_user.role == ROLE[:intern]
    user_ids = TimeSheet.where(date: {"$gte" => from_date, "$lte" => to_date}).distinct(:user_id)
    users = User.not_in(id: user_ids)
    users.where(status: STATUS[2], "$or" => [{role: ROLE[:employee]}, {role: ROLE[:intern]}]).order("public_profile.first_name" => :asc)
  end

  def self.get_users_who_not_filled_timesheet(from_date, to_date)
    users          = User.get_approved_users_to_send_reminder
    employee_list  = []
    timesheet_data = []
    users.each do| user |
      next if user.user_projects.empty?
      next if user.projects.where(timesheet_mandatory: true).count.eql?(0)
      user_and_date  = []
      timesheet_data = get_time_sheet(user, from_date, to_date)
      unless timesheet_data.empty?
        (from_date..to_date).each do |date|
          date_wise = []
          next if HolidayList.is_holiday?(date)
          next if user_on_leave?(user, date)
          next if time_sheet_filled?(user, date)
          date_wise.push(user.employee_detail.employee_id, user.name, user.email, date)
          employee_list << date_wise
        end
      else
        user_and_date.push(user.employee_detail.employee_id, user.name, user.email, "#{from_date} To #{to_date}")
        employee_list << user_and_date
      end
    end
    send_employee_list_through_mail(employee_list, from_date, to_date) if employee_list.present?
  end

  def self.get_time_sheet(user, from_date, to_date)
    TimeSheet.where(date: {"$gte" => from_date, "$lte" => to_date}).where(user_id: user.id)
  end

  def self.get_holiday_count(from_date, to_date)
    HolidayList.where(holiday_date: {"$gte" => from_date, "$lte" => to_date}).count
  end

  def self.time_sheet_present_for_reminder?(user)
    unless user.time_sheets.present?
      slack_uuid = user.public_profile.slack_handle
      message = "You haven't filled the timesheet for yesterday. Go ahead and fill it now. You can fill your timesheet <a href='#{'https://' + ENV['DOMAIN_NAME'] + '/time_sheets'}' target='_blank'> here </a> for past 7 days. If it exceeds 7 days then contact your manager."
      text_for_slack = "*#{message}*"
      text_for_email = "#{message}"
      TimesheetRemainderMailer.send_timesheet_reminder_mail(user, slack_uuid, text_for_email).deliver_now!
      send_reminder(slack_uuid, text_for_slack) unless slack_uuid.blank?
      return false
    end
    return true
  end

  def self.user_on_leave?(user, date)
    return false unless user.leave_applications.present?
    leave_applications = user.leave_applications.order("end_at asc").where(:end_at.gte => date,
                         leave_status: LEAVE_STATUS[1])
    leave_applications.each do |leave_application|
      return true if date.between?(leave_application.start_at, leave_application.end_at)
    end
    return false
  end

  def self.time_sheet_filled?(user, date)
    filled_time_sheet_dates = user.time_sheets.pluck(:date)
    return false unless filled_time_sheet_dates.include?(date)
    return true
  end

  def self.unfilled_timesheet_present?(user, unfilled_timesheet)
    if unfilled_timesheet.present?
      slack_handle = user.public_profile.slack_handle
      message1 = "You haven't filled the timesheet from"
      unfilled_timesheet_date = [unfilled_timesheet.to_date, "2020-05-01".to_date].max
      message2 = "Go ahead and fill it now. You can fill your timesheet <a href='#{'https://' + ENV['DOMAIN_NAME'] + '/time_sheets'}' target='_blank'> here </a> for past 7 days. If it exceeds 7 days then contact your manager."
      text_for_slack = "*#{message1} #{unfilled_timesheet_date}. #{message2}*"
      text_for_email = "#{message1} #{unfilled_timesheet_date}. #{message2}"
      pending_more_than_threshold = (Date.today - unfilled_timesheet_date) > PENDING_THRESHOLD
      TimesheetRemainderMailer.send_timesheet_reminder_mail(user, slack_handle, text_for_email, pending_more_than_threshold).deliver_now!
      send_reminder(slack_handle, text_for_slack) unless slack_handle.blank? rescue "Error in sending reminder to slack"
      return true
    end
    return false
  end

  def self.update_time_sheet(time_sheets, current_user, params)
    return_value = []
    updated_time_sheets = []
    params['time_sheets_attributes'].each do |key, value|
      time_sheet = time_sheets.find(value[:id])
      value['updated_by'] = current_user.id
      updated_time_sheets << time_sheet
      unless value[:from_time].blank? or value[:to_time].blank?
        value['from_time']  = value['date'] + ' ' + value['from_time']
        value['to_time']    = value['date'] + ' ' + value['to_time']
        unless time_sheet.time_validation(value['date'], value['from_time'], value['to_time'], 'from_ui')
          return_value << false
          next
        end
      end
      if time_sheet.update_attributes(value)
        return_value << true
      else
        return_value << false
      end
    end
    return return_value, updated_time_sheets
  end

  def self.create_time_sheet(user_id, current_user, params)
    time_sheets = []
    return_value = []
    params['time_sheets_attributes'].each do |key, value|
      value['user_id']    = user_id
      value['created_by'] = current_user.id
      time_sheet = TimeSheet.new
      value.delete("_destroy")
      unless value[:from_time].blank? or value[:to_time].blank?
        value['from_time']  = value['date'] + ' ' + value['from_time']
        value['to_time']    = value['date'] + ' ' + value['to_time']
        unless time_sheet.time_validation(value['date'], value['from_time'], value['to_time'], 'from_ui')
          return_value << false
          time_sheets << time_sheet
          next
        end
      end
      time_sheet.attributes = value
      if time_sheet.save
        return_value << true
      else
        time_sheets << time_sheet
        return_value << false
      end
    end
    return return_value, time_sheets
  end

  def self.get_errors_message(user, time_sheet_date)
    user.time_sheets.where(date: time_sheet_date.to_date).each do |time_sheet|
      return time_sheet.errors.full_messages if time_sheet.errors.full_messages.present?
    end
  end

  def self.calculate_date_difference(last_filled_time_sheet_date)
    TimeDifference.between(DateTime.current, DateTime.parse(last_filled_time_sheet_date.to_s)).in_days.round
  end

  def self.send_reminder(user_id, text)
    resp = JSON.parse(SlackApiService.new.open_direct_message_channel(user_id))
    SlackApiService.new.post_message_to_slack(resp['channel']['id'], text)
    SlackApiService.new.close_direct_message_channel(resp['channel']['id'])
    sleep 1
  end

  def load_project(user, display_name)
    user.first.projects.where(display_name: /^#{display_name}$/i).first
  end

  def self.create_error_message_for_slack(errors)
    errors.map! do |error|
      error.prepend("\`Error :: ").concat("\`")
    end
    errors
  end

  def self.create_error_message_while_updating_time_sheet(error)
    index = error.remove!("`").index(/Error/)
    error = error[index..-1] unless index.nil?
    error
  end

  def self.create_error_message_while_creating_time_sheet(errors)
    errors.map! do |error|
      index = error.remove!("`").index(/Error/)
      error[index..-1] unless index.nil?
    end
    errors
  end

  def self.load_user(user_id)
    User.where("public_profile.slack_handle" => user_id)
  end

  def self.fetch_email_and_associate_to_user(user_id)
    call_slack_api_service_and_fetch_email(user_id)
  end

  def self.approved_leaves_count(user, from_date, to_date)
    leaves_count = 0
    leave_applications = user.leave_applications.where(
      "$and" => [{start_at: {"$gte" => from_date, "$lte" => to_date}},
                {leave_status: LEAVE_STATUS[1]}]
    )
    leave_applications.sum(:number_of_days)
  end

  def self.get_time_sheet_between_range(user, project_id, from_date, to_date)
    user.time_sheets.where(project_id: project_id, date: {"$gte" => from_date, "$lte" => to_date}).order_by(date: :asc)
  end

  def self.get_project_name(project_id)
    Project.find_by(id: project_id).name
  end

  def self.get_time_sheet_of_date(user, date)
    user.time_sheets.where(date: date.to_date)
  end

  def self.from_date_less_than_to_date?(from_date, to_date)
    return false if from_date.blank? or to_date.blank?
    from_date.to_date <= to_date.to_date
  end

  def self.load_user_with_id(user_id)
    User.find_by(id: user_id)
  end

  def self.load_project_with_id(project_id)
    Project.find_by(id: project_id)
  end

  def self.get_users_and_timesheet_who_have_filled_timesheet_for_different_project
    activity_ids = Project.where(is_activity: true).pluck(:id)
    User.approved.each do | user |
      user_timesheet = []
      date           = Date.yesterday
      time_sheets    = user.time_sheets.where(
        :created_at => date.beginning_of_day..date.end_of_day,
        :project_id.nin => activity_ids
      )
      next if time_sheets.empty?
      time_sheets.each do|time_sheet|
        time_sheet_data = {}
        next if user.user_projects.where(project_id: time_sheet.project_id).exists?
        duration = DURATION_HASH[time_sheet.duration].nil? ? time_sheet.duration.to_s + "mins" : DURATION_HASH[time_sheet.duration]
        time_sheet_data = {
          project_name: time_sheet.project.name,
          date:         time_sheet.date,
          from_time:    time_sheet.from_time,
          to_time:      time_sheet.to_time,
          duration:     duration,
          description:  time_sheet.description
        }
        user_timesheet << time_sheet_data
      end
      if user_timesheet.present?
        TimesheetRemainderMailer.user_timesheet_for_different_project(user, user_timesheet).deliver_now
      end
    end
  end

  # conversion of minutes into milliseconds
  def self.load_timesheet(timesheet_ids, from_date, to_date)
    TimeSheet.collection.aggregate(
      [
        {
          "$match" => {
            "date" => {
              "$gte" => from_date,
              "$lte" => to_date
            },
            "_id" => {
              "$in" => timesheet_ids
            }
          }
        },
        {
          "$group" => {
            "_id" => {
              "user_id" => "$user_id",
              "project_id" => "$project_id"
            },
            "totalSum" => {
              "$sum" => "$duration"
            }
          }
        },
        {
          "$group" => {
            "_id" => "$_id.user_id",
            "working_status" => {
              "$push" => {
                "project_id" => "$_id.project_id",
                "total_time" => {
                  "$multiply" => [
                    "$totalSum",
                    60,
                    1000
                  ]
                }
              }
            }
          }
        }
      ]
    )
  end

  # duration is in minutes and we are calculating worked hours by milliseconds
  def self.load_projects_report(from_date, to_date)
    TimeSheet.collection.aggregate([
      {
        "$match"=>{
          "date"=>{
            "$gte"=> from_date,
            "$lte"=> to_date
          }
        }
      },
      {
        "$group"=>{
          "_id"=>{
            "project_id"=>"$project_id"
          },
          "totalSum"=>{
            "$sum"=> {
              "$multiply" => [
                "$duration",
                60,
                1000
              ]
            }
          }
        }
      }
    ])
  end

  def self.get_users_and_total_worked_hours(date, duration)
    TimeSheet.collection.aggregate([
      {
        "$match" => {
          "date" => date
        }
      },
      {
        "$group" => {
          "_id" => {
            "user_id" => "$user_id"
          },
          "total_duration" => {
            "$sum" => "$duration"
          }
        }
      },
      {
        "$match" => {
          "total_duration" => {
            "$gte" => duration
          }
        }
      }
    ])
  end

  def self.load_time_sheet_and_calculate_total_work(project_id, from_date, to_date)
    TimeSheet.collection.aggregate([
      {
        "$match" => {
          "date" => {
            "$gte" => from_date,
            "$lte" => to_date
          },
          "project_id" => project_id
        }
      },
      {
        "$group" => {
          "_id" => {
            "date" => "$date",
            "user_id" => "$user_id"
          },
          "totalSum" => {
            "$sum" => {
              "$multiply" => [
                "$duration",
                60,
                1000
              ]
            }
          }
        }
      },
      {
        "$sort" => {
          "_id.date" => 1
        }
      },
      {
        "$group" => {
          "_id" => "$_id.user_id",
          "working_status" => {
            "$push" => {
              "date" => "$_id.date",
              "total_time" => "$totalSum"
            }
          }
        }
      }
    ])
  end

  def self.send_employee_list_through_mail(employee_list,from_date, to_date)
    emails  = User.get_hr_emails
    headers = ['Employee ID', 'Employee Name', 'Employee Email', 'Date_Not_filled']
    csv     = generate_report_in_csv_format(headers, employee_list)
    text    = "PFA Employee List- Who have not filled timesheet from #{from_date} to #{to_date}"
    options = { csv: csv, text: text, emails: emails, from_date: from_date, to_date: to_date }
    WeeklyTimesheetReportMailer.send_report_who_havent_filled_timesheet(options).deliver_now!
  end

  def self.generate_summary_report(from_date, to_date, params, current_user)
    project_employee = create_all_projects_employees_timesheet_summary(from_date.to_date, to_date.to_date)
    projects_summary = create_all_projects_summary(from_date, to_date)
    employee_summary = create_all_employee_summary(from_date, to_date)
    subject          = "Timesheet summary report from #{from_date} to #{to_date}"
    options          = {
      project_employee: project_employee,
      projects_summary: projects_summary,
      employee_summary: employee_summary,
      params:           params,
      user_email:       current_user.email,
      user_name:        current_user.name,
      from_date:        from_date,
      to_date:          to_date,
      subject:          subject
    }
  end

  def self.generate_project_report(from_date, to_date, project, params, current_user)
    report  = create_project_timesheet_report(project, from_date.to_date, to_date.to_date)
    subject = "Timesheet report - #{project.name} from #{from_date} to #{to_date}"
    options = {
      report:       report,
      project_name: project.name,
      params:       params,
      user_email:   current_user.email,
      user_name:    current_user.name,
      from_date:    from_date,
      to_date:      to_date,
      subject:      subject
    }
  end
end
