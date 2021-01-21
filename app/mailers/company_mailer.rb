class CompanyMailer < ActionMailer::Base
  default from: 'intranet@joshsoftware.com',
          reply_to: 'hr@joshsoftware.com'

  def send_billing_location_report(username, user_email, billing_location)
    csv = Company.billing_location_report(billing_location)
    @username = username
    @billing_location = billing_location == COUNTRIES_ABBREVIATIONS[0] ? COUNTRIES[0] : COUNTRIES[1]
    attachments["BillingLocationDetails - #{Time.now.strftime("%d%b%Y-%H:%M")}.csv"] = csv
    mail(subject: "Billing Location Details Report(#{billing_location})", to: user_email)
  end
end
