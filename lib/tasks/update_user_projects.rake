desc 'Update user projects active status and end date'
task update_user_projects: :environment do
  # update user_project status of inactive projects
  Project.where(is_active: false).each do |project|
    user_projects = project.user_projects.where(active: true)
    puts "\n Project Name: #{project.name}" if user_projects.present?
    user_projects.each do |user_project|
      if user_project.end_date.present?
        puts "Name: #{user_project.user.name}, Status Changed: false"
        user_project.set(active: false)
      else
        puts "Name: #{user_project.user.name}, Status Changed: false, End_date Changed: #{project.end_date}"
        user_project.set(active: false, end_date: project.end_date)
      end
    end
  end

  # update end_date of active user project whose project end_date is present
  Project.where(is_active: true, :end_date.ne => nil).each do |project|
    user_projects = project.user_projects.where(active: true)
    end_date = project.end_date
    puts "\n Project Name: #{project.name}" if user_projects.present?
    user_projects.each do |user_project|
      if user_project.end_date.present? && (project.end_date >= user_project.end_date)
        end_date = user_project.end_date
      end
      puts "Name: #{user_project.user.name}, End_date Changed: #{project.end_date}"
      user_project.update_attributes(end_date: end_date)
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
end
