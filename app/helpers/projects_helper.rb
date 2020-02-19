module ProjectsHelper

  def active_project_ids(user)
    user_projects = user.projects.all_active.pluck(:name, :id)
    project_ids   = user_projects.inject([]) { |arr, i| arr << i.last; arr }
    all_project   = Project.all_active.not_in(:_id => project_ids).pluck(:name, :id)
    (user_projects + all_project)
  end

  def employee_name
    all_employee_names =[]
    users = User.where(:role.nin => ['HR','Finance'], :status => STATUS[2])
    users.each do|user|
      full_name = user.public_profile.first_name + user.public_profile.last_name
      all_employee_names << [full_name, user.id]
    end
    all_employee_names
  end
end
