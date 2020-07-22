class CodeMonitoringService
  def self.call(params)
    url     = URI(ENV['CODE_MONITOR_URL'])
    https   = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new(
      url.path,
      'Content-Type' => 'application/json'
    )
    request.body = params.to_json
    response = https.request(request)
    unless response.message == 'OK'
      puts "------ GitQuest Response Error----TODO : remove these messages later"
      puts params
      puts "RESP MESSAGE: #{response.msg}"
      puts "RESP BODY: #{JSON.parse(response.try(:body))}"
    end
  end
end