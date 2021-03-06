module ProjectsHelper

  def active_project_ids(user)
    user_projects = user.projects.all_active.pluck(:name, :id)
    return user_projects if current_user.role == ROLE[:consultant]
    project_ids   = user_projects.inject([]) { |arr, i| arr << i.last; arr }
    all_project   = Project.all_active.not_in(:_id => project_ids).pluck(:name, :id)
    (user_projects + all_project)
  end

  def get_users_projects(user)
    user.user_projects.where(active: true).nin(project: @project.id)
  end

  def get_wfo_batch_name
    unless HolidayList.is_weekend?(Date.today)
      Date.today.day.odd? ? 'Alpha' : 'Bravo'
    else
      'NA'
    end
  end
end
