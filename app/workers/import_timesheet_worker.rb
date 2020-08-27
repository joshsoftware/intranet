class ImportTimesheetWorker
  include Sidekiq::Worker

  def perform(file, file_name, email)
    processed_timesheets = []
    csv = CSV.read(file, headers: true)
    service = ProcessTimesheetService.new
    csv.each do |row|
      if check_values(row)
        processed_timesheets << service.call(row)
      else
        processed_timesheets << service.update_status(row, 'Should Enter all Fields')
      end
    end

    service.send_report(processed_timesheets, file_name, email)
  end

  def check_values(row)
    row['Email'].present? &&
    row['Project'].present? && 
    row['Date'].present? &&
    row['Duration'].present? &&
    row['Description'].present?
  end
end
