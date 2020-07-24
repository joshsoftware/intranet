class LightAirUserMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
 
  def send_opt_out_users_report(csv, emails)
    @date = Date.today.strftime("%d-%m-%Y")
    attachments["josh_newsletter_opt_out_users_report_#{Date.today}.csv"] = csv
    mail(subject: "Josh Newsletter Opt-Out Users List till - #{@date}", to: emails)
  end
end
