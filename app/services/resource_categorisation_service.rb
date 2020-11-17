class ResourceCategorisationService

  def initialize(emails)
    @emails = emails
    load_projects
  end

  def call
    generate_resource_report
    ReportMailer.send_resource_categorisation_report(@report, @emails).deliver_now
  end

  def generate_resource_report
    bench_resource = []
    devops_ui_ux_resource = []
    ui_ux_designation = [
      'UI/UX Lead',
      'UI/UX Designer',
      'Senior UI/UX Designer',
    ]
    devops_project = Project.where(name: 'DevOps Work').first
    devops_engg = UserProject.where(project_id: devops_project.id, active: true).pluck(:user_id)
    exclude_designations = [
      'Assistant Vice President - Sales',
      'Business Development Executive',
      'Office Assistant',
      'Delivery Manager',
      'Assistant Manager - Accounts',
      'Director'
    ]

    User.approved.where(:role.in => ['Employee', 'Intern'], :'employee_detail.location'.ne => LOCATIONS[0]).each do |user|
      unless exclude_designations.include?(user.designation.try(:name))
        billable_allocation = billable_projects_allocation(user)
        billable_allocation = billable_allocation > 160 ? 160 : billable_allocation
        non_billable_allocation = non_billable_projects_allocation(user)
        investment_allocation = investment_projects_allocation(user)
        total_allocation = billable_allocation + non_billable_allocation + investment_allocation
        bench_allocation =  (160 - total_allocation) < 0 ? 0 : (160 - total_allocation)
        project_names = user.project_details.map { |i| i.values[1] }

        technical_skills = user.public_profile.try('technical_skills').slice(0,3)

        next devops_ui_ux_resource.append(
          add_resource_record(user, technical_skills, project_names).merge(non_billable: 160, total_allocation: 160)
        ) if ui_ux_designation.include?(user.designation.try(:name)) || devops_engg.include?(user.id)

        next bench_resource.append(
          add_resource_record(user, technical_skills, project_names).merge(bench: 160)
        ) if total_allocation == 0

        @report[:resource_report] << add_resource_record(user, technical_skills, project_names).merge(
          total_allocation: total_allocation,
          billable: billable_allocation,
          non_billable: non_billable_allocation,
          investment: investment_allocation,
          bench: bench_allocation
        )
      end
    end

    @report[:resource_report] = @report[:resource_report].sort_by { |k,v| k[:name] }
    devops_ui_ux_resource = devops_ui_ux_resource.sort_by { |k,v| k[:name] }
    bench_resource = bench_resource.sort_by { |k,v| k[:name] }
    @report[:resource_report] = @report[:resource_report] + devops_ui_ux_resource + bench_resource
    @report[:project_wise_resource_report] = @report[:project_wise_resource_report].sort_by { |k,v| k[:project] }
    @report
  end

  def billable_projects_allocation(user)
    user_projects = UserProject.where(
      :project_id.in => @billable_projects,
      active: true,
      billable: true,
      user_id: user.id
    )

    add_project_wise_details(user, user_projects, 'billable')
    user_projects.pluck(:allocation).sum
  end

  def non_billable_projects_allocation(user)
    user_projects = UserProject.where(
      :project_id.in => @non_billable_projects,
      active: true,
      billable: false,
      user_id: user.id
    )

    add_project_wise_details(user, user_projects, 'non_billable')
    user_projects.pluck(:allocation).sum
  end

  def investment_projects_allocation(user)
    user_projects = UserProject.where(
      :project_id.in => @investment_projects,
      active: true,
      user_id: user.id
    )

    add_project_wise_details(user, user_projects, 'investment')
    user_projects.pluck(:allocation).sum
  end

  def add_project_wise_details(user, user_projects, allocation_type)
    user_projects.each do |user_project|
      allocation = user_project.allocation
      next if allocation == 0
      allocation_type = 'non_billable' if user_project.billable == false
      @report[:project_wise_resource_report] << add_project_wise_resource_record(user).merge(
        "#{allocation_type}": allocation,
        project: user_project.project.name
      )
    end
  end

  def add_resource_record(user, technical_skills, project_names)
    {
      name: user.name,
      location: user.location,
      designation: user.designation.try(:name),
      total_allocation: 0,
      billable: 0,
      non_billable: 0,
      investment: 0,
      bench: 0,
      technical_skills: technical_skills,
      projects: project_names
    }
  end

  def add_project_wise_resource_record(user)
    {
      name: user.name,
      location: user.location,
      designation: user.designation.try(:name),
      billable: 0,
      non_billable: 0,
      investment: 0,
      project: ''
    }
  end

  def load_projects
    @report = {
      resource_report: [],
      project_wise_resource_report: []
    }

    @billable_projects = Project.where(
      :type_of_project.in => ['T&M', 'Fixbid'],
      is_active: true
    ).pluck(:id)

    @non_billable_projects = Project.where(
      :type_of_project.in => ['T&M', 'Free', 'Fixbid'],
      is_active: true
    ).pluck(:id)

    @investment_projects = Project.where(
      type_of_project: 'Investment',
      is_active: true,
      is_activity: false
    ).pluck(:id)
  end
end
