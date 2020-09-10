class WeeklyTimesheetReportMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
  
  def send_weekly_timesheet_report(csv, email, unfilled_time_sheet_report)
    @unfilled_time_sheet_report = unfilled_time_sheet_report
    attachments["WeeklyTimesheetReport - #{Date.today}.csv"] = csv
    emails = ([email] + DEFAULT_TIMESHEET_MANAGERS).uniq
    mail(subject: 'Weekly timesheet report', to: emails)
  end

  def send_weekend_timesheet_report(csv, start_date)
    attachments["WeekendTimesheetReport - #{Date.today}.csv"] = csv
    hr_emails = User.approved.where(role: 'HR').collect(&:email)
    emails = [ 'sameert@joshsoftware.com', 
               'shailesh.kalekar@joshsoftware.com',
               hr_emails ].flatten
    @start_date = start_date.strftime('%d %B')
    mail(
      subject: "Weekend Timesheet Report (#{start_date.strftime('%d %B')} - #{Date.today.strftime('%d %B')})",
      to: emails
    )
  end

  def send_employees_working_hour_report(csv, start_date)
    attachments["EmployeesWorkingHourReport - #{Date.today}.csv"] = csv
    hr_emails = User.approved.where(role: 'HR').collect(&:email)
    emails = [ 'sameert@joshsoftware.com', 
               'shailesh.kalekar@joshsoftware.com',
               hr_emails ].flatten
    @start_date = start_date.strftime('%d %B')
    mail(
      subject: "Employee Report - Worked More than 9 Hours During (#{start_date.strftime('%d %B')} - #{(Date.today - 1).strftime('%d %B')})",
      to: emails
    )
  end

  def send_report_who_havent_filled_timesheet( options = {} )
    @text = options[:text]
    attachments["EmployeesNotFilledTimesheet.csv"] = options[:csv]
    mail(
      subject:"Employees List-  who haven't filled timesheet between #{options[:from_date]} to #{options[:to_date]} ",
      to: options[:emails]
    )
  end

  def send_timesheet_summary_report( options = {} )
    @user_name = options[:user_name]
    data_file  = render_to_string(
      layout: false, handlers: [:axlsx], formats: [:xlsx],
      template: 'time_sheets/export_project_report',
      locals: { project_employee: options[:project_employee],
                projects_summary: options[:projects_summary],
                employee_summary: options[:employee_summary],
                report: options[:report],
                params: options[:params],
                project_name: options[:project_name]
              }
    )

    attachment = { mime_type: Mime[:xlsx],
                   content: data_file }

    attachments["TimesheetReportFrom - #{options[:from_date]} to #{options[:to_date]}.xlsx"] = attachment
    mail(
      subject: options[:subject],
      to: options[:user_email]
    )
  end
end
