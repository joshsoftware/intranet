class WeeklyTimesheetReportMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
  
  def send_weekly_timesheet_report(csv, email, unfilled_time_sheet_report)
    @unfilled_time_sheet_report = unfilled_time_sheet_report
    attachments["weekly_timesheet_report_#{Date.today}.csv"] = csv
    emails = ([email] + DEFAULT_TIMESHEET_MANAGERS).uniq
    mail(subject: 'Weekly timesheet report', to: emails)
  end

  def send_report_who_havent_filled_timesheet( options = {} )
    @text = options[:text]
    attachments["Employees- Not Filled Timesheet.csv"] = options[:csv]
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
    attachment = Base64.encode64(data_file)
    attachments["Timesheet_report_from #{options[:from_date]} to #{options[:to_date]}.xlsx"] = {mime_type: Mime[:xlsx], content: attachment, encoding: 'base64'}
    mail(
      subject: options[:subject],
      to: options[:user_email]
    )
  end
end
