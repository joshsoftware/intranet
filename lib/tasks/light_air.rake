require 'csv'
namespace :light_air do
  desc 'Send report of Opt-Out Users to HR every month'
  task :send_opt_out_users_report => :environment do
    
    user_reports = []
    opt_out_users = Light::User.where(sidekiq_status: 'Unsubscribed')
                               .order_by(:unsubscribed_at.desc)           
    opt_out_users.each do |u|
      user_reports << [ u.username,
                        u.email_id,
                        u.sidekiq_status,
                        date_format(u.subscribed_at),
                        date_format(u.unsubscribed_at) ]
    end
    
    hr_emails = User.where(role: 'HR', status: 'approved').map(&:email)
    user_reports_csv = generate_csv(user_reports)

    LightAirUserMailer.send_opt_out_users_report(user_reports_csv, hr_emails).deliver_now!
  end

  def date_format(date)
    date.present? ? date.strftime("%d-%m-%Y") : 'N/A'
  end

  def generate_csv(user_reports)
    headers = ['Name', 'Email Id', 'Status', 'Opt-In At', 'Opt-Out At']
    csv = 
      CSV.generate(headers: true) do |csv|
        csv << headers
        user_reports.each do |user|
          csv << user
        end
      end
    csv
  end
end