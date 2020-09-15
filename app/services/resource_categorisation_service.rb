class ResourceCategorisationService

  def initialize(emails)
    @emails = emails
  end

  def call
    files = { resources: generate_resource_report }
    ReportMailer.send_resource_categorisation_report(files, @emails).deliver_now
  end

  def generate_resource_report
    resource_report = []
    exclude_designations = [
      'Assistant Vice President - Sales',
      'Business Development Executive',
      'Office Assistant'
    ]
    User.approved.where(:role.in => ['Employee', 'Intern']).each do |user|
      unless exclude_designations.include?(user.designation.try(:name))
        billable_allocation = billable_projects_allocation(user.id)
        billable_allocation = billable_allocation > 160 ? 160 : billable_allocation
        non_billable_allocation = non_billable_projects_allocation(user.id)
        investment_allocation = investment_projects_allocation(user.id)
        total_allocation = billable_allocation + non_billable_allocation + investment_allocation
        bench_allocation =  (160 - total_allocation) < 0 ? 0 : (160 - total_allocation)
        resource_report << { name: user.name,
                             total_allocation: total_allocation,
                             billable: billable_allocation,
                             non_billable: non_billable_allocation,
                             investment: investment_allocation,
                             bench: bench_allocation
                            }
      end
    end
    resource_report.sort_by { |k,v| k[:name] }
  end

  def billable_projects_allocation(user_id)
    projects = Project.where(:type_of_project.in => ['T&M', 'Fixbid'], is_active: true)
    UserProject.where(
      :project_id.in => projects.pluck(:id),
      active: true,
      billable: true,
      user_id: user_id
    ).pluck(:allocation).sum
  end

  def non_billable_projects_allocation(user_id)
    projects = Project.where(:type_of_project.in => ['T&M', 'Free', 'Fixbid'], is_active: true)
    UserProject.where(
      :project_id.in => projects.pluck(:id),
      active: true,
      billable: false,
      user_id: user_id
    ).pluck(:allocation).sum
  end

  def investment_projects_allocation(user_id)
    projects = Project.where(type_of_project: 'Investment', is_active: true, is_activity: false)
    UserProject.where(
      :project_id.in => projects.pluck(:id),
      active: true,
      user_id: user_id
    ).pluck(:allocation).sum
  end
end
