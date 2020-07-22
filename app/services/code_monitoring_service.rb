class CodeMonitoringService
  def self.call(params)
    unless Rails.env.development?
      CodeMonitoringWorker.perform_async(params)
    end
  end
end