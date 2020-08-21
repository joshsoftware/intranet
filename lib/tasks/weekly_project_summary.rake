desc "Instanciate Weekly Project Summary Email notification"
task :weekly_project_summary => :environment do
  projects = Project.all
  weeks = 4 # Number of weeks we want to add in Notification Email.
  projects.each do |project|
    if project.repositories.count > 0
      manager_emails = project.managers.pluck(:email)
      repo_data = {}
      project.repositories.each do |repo|
        data = repo.code_climate_statistics.order("created_at desc").limit(weeks).reverse
        if data.length > 0 && !manager_emails.empty?
          repo_data[repo.name] = data
        end
      end
      unless repo_data.keys.empty?
        # TODO: Remove following line after testing.
        manager_emails = ["anuja@joshsoftware.com", "swapnil@joshsoftware.com", "kaiwalya.pataskar@joshsoftware.com"]
        ProjectMailer.delay.send_weekly_project_summary(project.name, manager_emails, repo_data)
      end
    end
  end
end
