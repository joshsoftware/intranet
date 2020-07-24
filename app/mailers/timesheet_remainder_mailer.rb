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

  def user_timesheet_for_diffrent_project(user, timesheets)
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
end
