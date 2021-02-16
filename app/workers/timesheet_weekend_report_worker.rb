class TimesheetWeekendReportWorker
  include Sidekiq::Worker

  def perform(from_date, to_date, email)
    TimesheetWeekendService.new(from_date, to_date, email).call
  end
end
