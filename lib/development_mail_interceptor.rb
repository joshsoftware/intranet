class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "#{message.to} #{message.subject}"
    message.to = "pramod@joshsoftware.com", "sanjiv@joshsoftware.com"
  end
end
