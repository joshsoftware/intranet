class TimeSheet
  include Mongoid::Document
  include Mongoid::Timestamps
  extend CheckUser

  field :user_id
  field :project_id
  field :date,            :type => Date
  field :from_time,       :type => Time
  field :to_time,         :type => Time
  field :description,     :type => String

  belongs_to :user
  belongs_to :project

  validates :from_time, :to_time, uniqueness: { scope: [:user_id, :date], message: "record is already present" }

  MAX_TIMESHEET_COMMAND_LENGTH = 5
  DATE_FORMAT_LENGTH = 3
  MAX_DAILY_STATUS_COMMAND_LENGTH = 2
  WORKED_HOURSE = 8

  def self.parse_timesheet_data(params)
    split_text = params['text'].split

    return false unless valid_command_format?(split_text, params['channel_id'])
    return false unless valid_project_name?(split_text[0], params)
    return false unless valid_date_format?(split_text[1], params)
    return false unless time_validation(split_text[1], split_text[2], split_text[3], params)

    time_sheets_data = time_sheets(split_text, params)
    return true, time_sheets_data
  end

  def self.valid_command_format?(split_text, channel_id)
    if split_text.length < MAX_TIMESHEET_COMMAND_LENGTH
      text = "\`Error :: Invalid timesheet format. Format should be <project_name> <date> <from_time> <to_time> <description>\`"
      SlackApiService.new.post_message_to_slack(channel_id, text)
      return false
    end
    return true
  end

  def self.valid_project_name?(project_name, params)
    user = load_user(params['user_id'])
    project = user.first.projects.find_by(display_name: /^#{project_name}$/i) rescue nil
    return true if !project.nil? || project_name == 'other'
    text = "\`Error :: You are not working on this project. Use /projects command to view your project\`"
    SlackApiService.new.post_message_to_slack(params['channel_id'], text)
    return false
  end

  def self.valid_date_format?(date, params)
    split_date = date.include?('/')? date.split('/') : date.split('-')
    
    if split_date.length < DATE_FORMAT_LENGTH
      text = "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end

    valid_date?(split_date, date, params)
  end

  def self.valid_date?(split_date, date, params)
    valid_date = Date.valid_date?(split_date[2].to_i, split_date[1].to_i, split_date[0].to_i)
    unless valid_date
      SlackApiService.new.post_message_to_slack(params['channel_id'], "\`Error :: Invalid date\`")
      return false
    end

    return true if params['command'] == '/daily_status'
    return false unless timesheet_date_greater_than_assign_project_date(date, params)
    check_date_range(date, params)
  end
  
  def self.timesheet_date_greater_than_assign_project_date(date, params)
    split_text = params['text'].split
    user = load_user(params['user_id'])
    project = load_project(user, split_text[0])
    user_project = UserProject.find_by(user_id: user.first.id, project_id: project.id, end_date: nil)
    if date.to_date < user_project.start_date
      text = "\`Error :: Not allowed to fill timesheet for this date. As you were not assigned on project for this date\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def self.check_date_range(date, params)
    if Date.parse(date) < 7.days.ago
      text = "\`Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    elsif Date.parse(date) > Date.today
      text = "\`Error :: Can't fill the timesheet for future date.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def self.from_time_greater_than_to_time?(from_time, to_time, params)
    if from_time >= to_time
       text = "\`Error :: From time must be less than to time\`"
       SlackApiService.new.post_message_to_slack(params['channel_id'], text)
       return false
     end
     return true
  end

  def self.timesheet_greater_than_current_time?(from_time, to_time, params)
    if from_time >= Time.now || to_time >= Time.now
      text = "\`Error :: Can't fill the timesheet for future time.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def self.time_validation(date, from_time, to_time, params)
    from_time = valid_time?(date, from_time, params)
    to_time = valid_time?(date, to_time, params)
    return false unless from_time && to_time
    return false unless from_time_greater_than_to_time?(from_time, to_time, params)
    return false unless timesheet_greater_than_current_time?(from_time, to_time, params)

    return true, from_time, to_time
  end
  
  def self.valid_time?(date, time, params)
    time_format = check_time_format(time)

    if time_format
      return_value = Time.parse(date + ' ' + time_format) rescue nil
    end

    unless return_value
      text = "\`Error :: Invalid time format. Format should be HH:MM\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return_value
  end
  
  def self.check_time_format(time)
    return false if time.include?('.')
    return time + (':00') unless time.include?(':')
    time
  end

  def self.concat_desscription(split_text)
    description = ''
    split_text[4..-1].each do |string|
      description = description + string + ' '
    end
    description
  end

  def self.time_sheets(split_text, params)
    time_sheets_data = {}
    user = load_user(params['user_id'])
    project = load_project(user, split_text[0])
    time_sheets_data['user_id'] = user.first.id
    time_sheets_data['project_id'] = project.nil? ? nil : project.id
    time_sheets_data['date'] = Date.parse(split_text[1])
    time_sheets_data['from_time'] = Time.parse(split_text[1] + ' ' + split_text[2])
    time_sheets_data['to_time'] = Time.parse(split_text[1] + ' ' + split_text[3])
    time_sheets_data['description'] = concat_desscription(split_text)
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
      return false unless valid_date_format?(date, params)
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

  def self.check_time_sheet(user)
    return false unless user.time_sheets.present?
    return true
  end

  def self.user_on_leave?(user, date)
    return false unless user.leave_applications.present?
    leave_applications = user.leave_applications.where(:start_at.gte => date)
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
      hours, minitues = calculate_hours_and_minutes(total_minutes.to_i)
      next if hours == 0 && minitues == 0
      time_sheet_message += " *#{project.name}: #{hours}H #{minitues}M*"
      total_minutes = 0
    end
    return time_sheet_log, time_sheet_message
  end

  def self.generete_employee_timesheet_report(timesheets, from_date, to_date)
    timesheet_reports = []
    timesheets.each do |timesheet|
      user = load_user_with_id(timesheet['_id'])
      users_timesheet_data = {}
      users_timesheet_data['user_name'] = user.name
      users_timesheet_data['user_id'] = user.id
      project_details = []
      total_work = 0
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
      users_timesheet_data['leaves'] = get_user_leaves_count(user, from_date, to_date)
      timesheet_reports << users_timesheet_data
    end
    timesheet_reports.sort{|previous_record, next_record| previous_record['user_name'] <=> next_record['user_name']}
  end


  def self.create_projects_report_in_json_format(projects_report, from_date, to_date)
    projects_report_in_json = []
    projects_report.each do |project_report|
      project_details = {}
      project = load_project_with_id(project_report['_id']['project_id'])
      project_details['project_name'] = project.name
      project_details['no_of_employee'] = project.get_user_projects_from_project(from_date, to_date).count
      total_hours = convert_milliseconds_to_hours(project_report['totalSum'])
      project_details['total_hours'] = convert_hours_to_days(total_hours)
      project_details['allocated_hours'] = get_allocated_hours(project, from_date, to_date)
      project_details['leaves'] = total_leaves_on_project(project, from_date, to_date)
      projects_report_in_json << project_details
      project_details = {}
    end
    projects_report_in_json
  end

  def self.generate_individual_timesheet_report(user, params)
    time_sheet_log = []
    individual_time_sheet_data = {}
    total_minutes = 0
    total_minutes_worked_on_projects = 0
    user.worked_on_projects(params[:from_date], params[:to_date]).includes(:time_sheets).each do |project|
      project.time_sheets.where(user_id: user.id, date: {"$gte" => params[:from_date], "$lte" => params[:to_date]}).order_by(date: :asc).each do |time_sheet|
        time_sheet_data = []
        from_time, to_time = format_time(time_sheet)
        working_minutes = calculate_working_minutes(time_sheet)
        hours, minutes = calculate_hours_and_minutes(working_minutes.to_i)
        time_sheet_data.push(time_sheet.date, from_time, to_time,"#{hours}:#{minutes}", time_sheet.description)
        time_sheet_log << time_sheet_data
        total_minutes += working_minutes
        total_minutes_worked_on_projects += working_minutes
        time_sheet_data = []
      end
      working_details = {}
      hours, minitues = calculate_hours_and_minutes(total_minutes.to_i)
      working_details['daily_status'] = time_sheet_log
      working_details['total_worked_hours'] = "#{hours}:#{minitues}"
      individual_time_sheet_data["#{project.name}"] = working_details
      time_sheet_log = []
      working_details = {}
      total_minutes = 0
    end
    total_work_and_leaves = get_total_work_and_leaves(user, params, total_minutes_worked_on_projects.to_i)
    return individual_time_sheet_data, total_work_and_leaves
  end

  def self.format_time(time_sheet)
    from_time = time_sheet.from_time.strftime("%I:%M%p")
    to_time = time_sheet.to_time.strftime("%I:%M%p")

    return from_time, to_time
  end

  def self.get_total_work_and_leaves(user, params, total_minutes_worked_on_projects)
    total_work_and_leaves = {}
    total_worked_hours = total_worked_in_hours(total_minutes_worked_on_projects.to_i)
    total_work_and_leaves['total_work'] = convert_hours_to_days(total_worked_hours)
    total_work_and_leaves['leaves'] = get_user_leaves_count(user, params[:from_date], params[:to_date])
    total_work_and_leaves
  end

  def self.calculate_working_minutes(time_sheet)
    TimeDifference.between(time_sheet.to_time, time_sheet.from_time).in_minutes
  end

  def self.get_allocated_hours(project, from_date, to_date)
    total_allocated_hourse = 0
    project.get_user_projects_from_project(from_date, to_date).each do |user|
      user_projects = user.get_user_projects_from_user(project.id, from_date, to_date)
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
        allocated_hours = working_days * WORKED_HOURSE
        total_allocated_hourse += allocated_hours
      end
    end
    convert_hours_to_days(total_allocated_hourse)
  end

  def self.get_working_days(from_date, to_date)
    working_days = from_date.business_days_until(to_date)
    no_of_holiday = get_holiday_count(from_date, to_date)
    working_days -= no_of_holiday
  end

  def self.total_leaves_on_project(project, from_date, to_date)
    total_leaves_count = 0
    project.get_user_projects_from_project(from_date, to_date).each do |user|
      user_projects = user.get_user_projects_from_user(project.id, from_date, to_date)
      user_projects.each do |user_project|
        leaves_count =
          if user_project.end_date.present?
            if from_date <= user_project.start_date
              get_user_leaves_count(user, user_project.start_date, user_project.end_date)
            elsif from_date > user_project.start_date
              get_user_leaves_count(user, from_date, user_project.end_date)
            end
          else
            if from_date <= user_project.start_date
              get_user_leaves_count(user, user_project.start_date, to_date)
            elsif from_date > user_project.start_date
              get_user_leaves_count(user, from_date, to_date)
            end
          end
        total_leaves_count += leaves_count
      end
    end
    total_leaves_count
  end

  def self.calculate_hours_and_minutes(total_minutes)
    hours, minutes = conver_minutes_into_hours(total_minutes)
    minutes = '%02i'%minutes
    return hours, minutes
  end

  def self.conver_minutes_into_hours(total_minutes)
    hours = total_minutes / 60
    minutes = total_minutes % 60
    return hours, minutes
  end

  def self.total_worked_in_hours(total_minutes)
    hours, minutes = conver_minutes_into_hours(total_minutes)
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
    days = total_allocated_hourse / WORKED_HOURSE
    hours = total_allocated_hourse % WORKED_HOURSE
    result = hours > 0 ? "#{days} Days #{hours}H (#{total_allocated_hourse}H)" : "#{days} Days (#{total_allocated_hourse}H)"
    result
  end

  def self.get_holiday_count(from_date, to_date)
    HolidayList.where(holiday_date: {"$gte" => from_date, "$lte" => to_date}).count
  end
  
  def self.load_project(user, display_name)
    user.first.projects.where(display_name: /^#{display_name}$/i).first
  end

  def self.load_user(user_id)
    User.where("public_profile.slack_handle" => user_id)
  end

  def self.fetch_email_and_associate_to_user(user_id)
    call_slack_api_service_and_fetch_email(user_id)
  end

  def self.get_user_leaves_count(user, from_date, to_date)
    user.leave_applications.where({start_at: {"$gte" => from_date, "$lte" => to_date}}).count
  end

  def self.get_project_name(project_id)
    Project.find_by(id: project_id).name
  end

  def self.from_date_less_than_to_date?(from_date, to_date)
    from_date.to_date <= to_date.to_date
  end

  def self.load_user_with_id(user_id)
    User.find_by(id: user_id)
  end
  
  def self.load_project_with_id(project_id)
    Project.find_by(id: project_id)
  end

  def self.load_timesheet(from_date, to_date)
    TimeSheet.collection.aggregate(
      [
        {
          "$match" => {
            "date" => {
              "$gte" => from_date,
              "$lte" => to_date
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
              "$sum" => {
                "$subtract" => [
                  "$to_time",
                  "$from_time"
                ]
              }
            }
          }
        },
        {
          "$group" => {
            "_id" => "$_id.user_id",
            "working_status" => {
              "$push" => {
                "project_id" => "$_id.project_id",
                "total_time" => "$totalSum"
              }
            }
          }
        }
      ]
    )
  end
  
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
            "$sum"=>{
              "$subtract"=>[
                "$to_time",
                "$from_time"
              ]
            }
          }
        }
      }
    ])
  end

end
