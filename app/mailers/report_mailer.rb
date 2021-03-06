class ReportMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
  
  def send_resource_categorisation_report(options, emails)
    data_file  = render_to_string(
      layout: false, handlers: [:axlsx], formats: [:xlsx],
      template: 'report_mailer/export_resource_categorisation_report',
      locals: {
        resource_report: options[:resource_report],
        project_wise_resource_report: options[:project_wise_resource_report]
      }
    )

    attachment = {
      mime_type: Mime[:xlsx],
      content: data_file
    }

    attachments["EmployeeCategorisationReport - #{Date.today}.xlsx"] = attachment
    mail(
      subject: "Employee Categorisation Report - #{Date.today}",
      to: emails
    )
  end

  def send_time_sheet_monthly_report(options, email)
    @username = User.where(email: email).first.name
    data_file  = render_to_string(
      layout: false, handlers: [:axlsx], formats: [:xlsx],
      template: 'report_mailer/export_time_sheet_monthly_report',
      locals: {reports: options}
    )

    attachment = {
      mime_type: Mime[:xlsx],
      content: data_file
    }

    attachments["TimesheetMonthlyReport - #{Date.today}.xlsx"] = attachment
    mail(
      subject: "Timesheet Monthly Report - #{Date.today}",
      to: email
    )
  end
end
