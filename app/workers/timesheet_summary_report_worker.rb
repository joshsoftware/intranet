class TimesheetSummaryReportWorker
  include Sidekiq::Worker

  def perform(params, from_date, to_date, user_id)
    current_user = User.where(id: user_id).first
    summary = params['summary']
    if summary.present?
      options = TimeSheet.generate_summary_report(from_date, to_date, summary, current_user)
    else
      project = Project.where(id: params['project_id']).first
      options = TimeSheet.generate_project_report(from_date, to_date, project, summary, current_user)
    end
    WeeklyTimesheetReportMailer.delay.send_timesheet_summary_report(options) if options.present?
  end
end
