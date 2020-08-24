class TimesheetRemainderMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'

  def send_timesheet_reminder_mail(user, slack_id, text, pending_more_than_threshold = false)
    managers_emails = []
    @user = user
    @text = text
    @projects = user.projects.map(&:name)
    managers_emails = @user.get_managers_emails_for_timesheet
    all_receivers = managers_emails + DEFAULT_TIMESHEET_MANAGERS + ['hr@joshsoftware.com']
    receivers = pending_more_than_threshold ? all_receivers : ['hr@joshsoftware.com']
    mail(subject: 'Timesheet Reminder', to: user.email, cc: receivers )
  end

  def user_timesheet_for_different_project(user, timesheets)
    managers_emails = []
    @user           = user
    managers_emails = @user.get_managers_emails_for_timesheet
    hr_emails       = User.get_hr_emails
    @timesheets     = timesheets
    mail(
      subject: 'Timesheet for project(s) which are not yet assigned',
      to: user.email,
      cc: managers_emails + hr_emails
    )
  end

  def import_timesheet_report(email, file_name, csv)
    user = User.where(email: email).first
    @user_name = user.public_profile.first_name
    @file_name = file_name
    csv_name = file_name.downcase.gsub(' ', '_')
    attachments["#{csv_name}_timesheet_file_#{Date.today}.csv"] = csv
    mail(
      subject: 'Result for Uploaded Timesheet File',
      to: email
    )
  end
end
