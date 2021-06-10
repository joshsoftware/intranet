desc 'Update user projects active status and end date'
task update_user_projects: :environment do
  # update user_project status and end_date of inactive projects
  inactive_pids = Project.where(is_active: false).pluck(:id)
  ups = UserProject.where(:project_id.in => inactive_pids)
  ups.each do |up|
    if up.active && up.end_date.present?
      puts "Project: #{up.project.name}, Name: #{up.user.name}, Status Changed: false"
      up.set(active: false)
    elsif up.active
      puts "Project: #{up.project.name}, Name: #{up.user.name}, Status Changed: false, End_date Changed: #{up.project.end_date}"
      up.set(active: false, end_date: up.project.end_date)
    elsif up.end_date.nil?
      puts "Project: #{up.project.name}, Name: #{up.user.name}, End_date Changed: #{up.project.end_date}"
      up.set(end_date: up.project.end_date)
    end
  end

  # update end date of active project set end date 31/Dec/2021 of each active project
  active_project = Project.where(is_active: true, end_date: nil)
  active_project.each do |project|
    puts "Project Name: #{project.name}, End Date set 31/Dec/2021"
    project.set(end_date: Date.today.end_of_year)
  end

  # update user_project end_date whose project end_date is present
  active_pids = Project.nin(id: inactive_pids, end_date: nil).pluck(:id)
  user_projects = UserProject.where(:project_id.in => active_pids, active: true)
  user_projects.each do |up|
    if up.end_date.nil? || (up.end_date.present? && up.project.end_date < up.end_date)
      print "\n Project Name: #{up.project.name} \t| Name: #{up.user.name}, " +
            "End_date Was: #{up.end_date}, End_date Changed: #{up.project.end_date}"
      up.update_attributes(end_date: up.project.end_date)
    end
  end
end

desc 'Update start date of inactive user projects where start date is greater than end date'
task update_start_date: :environment do
  puts 'Project Name | Employee Name | Start_date Changed'
  UserProject.where(active: false).each do |user_project|
    if user_project.start_date > user_project.end_date
      puts "#{user_project.project.name} | #{user_project.user.name} | #{user_project.end_date - 1}"
      user_project.set(start_date: user_project.end_date - 1)
    end
  end
end
