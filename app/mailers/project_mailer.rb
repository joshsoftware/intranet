class ProjectMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'

  def send_project_team_report(username, user_email)
    csv = Project.team_data_to_csv
    @username = username
    attachments["ProjectTeamsData - #{Time.now.strftime("%d%b%Y-%H:%M")}.csv"] = csv
    mail(subject: 'Project Team Data Report', to: user_email)
  end

  def send_weekly_project_summary(project_name, manager_emails, repo_data)
    @repo_data = repo_data
    @project_name = project_name
    mail(
      subject: "#{project_name} : Weekly Project Summary",
      to: manager_emails
    )
  end
end
