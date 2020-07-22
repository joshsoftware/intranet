class CodeMonitoringWorker
  include Sidekiq::Worker

  def perform(params)
    if !ENV['CODE_MONITOR_URL'].blank? && !Rails.env.development?
      CodeMonitoringService.call(params)
    end
  end
end
