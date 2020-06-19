class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "#{message.to} #{message.subject}"
    message.to = ENV['INTERCEPTOR_DEVELOPER_MAIL']
  end
end
