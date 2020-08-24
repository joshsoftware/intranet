class ProcessTimesheetService
  def call(row)
    process_file_and_create_timesheet(row)
  end

  def process_file_and_create_timesheet(row)
    errors = check_validations(row)
    if errors.present?
      update_status(row, "#{errors.join(" \n")}")
    else
      @timesheet.save(validate: false)
      update_status(row, 'Timesheet Created Successfully')
    end
  end

  def update_status(row, status)
    [
      row['Email'],
      row['Project'],
      row['Date'],
      row['Duration'],
      row['Description'],
      status
    ]
  end

  def check_validations(data)
    errors = []
    errors << 'User Email ID not found' unless user_exists?(data['Email'])
    errors << 'Project Not Found. Please check project name' unless project_exists?(data['Project'])
    errors << 'Timesheet record already Exists' if errors.blank? && timesheet_exists?(data)
    errors << "Timesheet total working hours can't exceed 24 hours." if errors.blank? && check_timesheet_working_hours?(data)
    errors.present? ? errors : false
  end

  def user_exists?(email)
    @user = User.where(email: email).first
    @user.present?
  end

  def project_exists?(project)
    @project = Project.where(name: project).first
    @project.present?
  end

  def timesheet_exists?(data)
    TimeSheet.where(
      date: data['Date'],
      user_id: @user.id,
      duration: data['Duration'],
      description: data['Description']
    ).exists?
  end

  def check_timesheet_working_hours?(data)
    @timesheet = TimeSheet.new(
      user_id: @user.id,
      project_id: @project.id,
      date: data['Date'],
      duration: data['Duration'],
      description: data['Description']
    )
    @timesheet.working_hours_less_than_max_threshold
    @timesheet.errors.present?
  end

  def send_report(reports, file_name, email)
    headers = ['Email', 'Project', 'Date', 'Duration', 'Description', 'Status']
    csv = TimeSheet.generate_report_in_csv_format(headers, reports)
    TimesheetRemainderMailer.import_timesheet_report(email, file_name, csv)
                            .deliver_now
  end
end
