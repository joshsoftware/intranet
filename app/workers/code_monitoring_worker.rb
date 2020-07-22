class CodeMonitoringWorker
  include Sidekiq::Worker

  def perform(params)
    unless ENV['CODE_MONITOR_URL'].blank?
      uri = URI(ENV['CODE_MONITOR_URL'])
      uri.query = URI.encode_www_form(params)
      Net::HTTP.get_response(uri)
    end
  end
end
