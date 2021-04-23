class TimesheetMonthlyReportWorker
  include Sidekiq::Worker
  
  def perform(from_date, to_date, email)
    TimesheetMonthlyService.new(from_date, to_date, email).call
  end
end