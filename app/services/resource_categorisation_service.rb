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
    bench_resources = []
    shared_resources = []
    include_roles = [ROLE[:employee], ROLE[:intern], ROLE[:manager], ROLE[:consultant]]

    users = User.approved.where(
      :role.in => include_roles,
      :'employee_detail.location'.ne => LOCATIONS[0],
      :'employee_detail.designation_id'.nin => @exclude_designations_ids
    )
    users.each do |user|
      billable_allocation = billable_projects_allocation(user)
      non_billable_allocation = non_billable_projects_allocation(user)
      investment_allocation = investment_projects_allocation(user)
      total_allocation = billable_allocation + non_billable_allocation + investment_allocation
      billable_allocation = billable_allocation > 160 ? 160 : billable_allocation
      non_billable_allocation = non_billable_allocation > 160 ? 160 : non_billable_allocation
      investment_allocation = investment_allocation > 160 ? 160 : investment_allocation
      record = {}
      record[:billable] = billable_allocation
      record[:non_billable] = non_billable_allocation
      record[:investment] = investment_allocation

      if is_shared_resource?(user)
        shared_allocation = 160 - (billable_allocation + investment_allocation + non_billable_allocation)
        shared_allocation = shared_allocation < 0 ? 0 : shared_allocation
        record[:shared] = shared_allocation
        record[:total_allocation] = total_allocation + shared_allocation
        shared_resources.append(
          add_resource_record(user).merge(record)
        )
        next
      end

      bench_allocation = (160 - total_allocation) < 0 ? 0 : (160 - total_allocation)
      total_allocation += bench_allocation
      record[:bench] = bench_allocation
      record[:total_allocation] = total_allocation

      next bench_resources.append(
        add_resource_record(user).merge(record)
      ) if bench_allocation == 160

      @report[:resource_report] << add_resource_record(user).merge(record)
    end

    @report[:resource_report] = @report[:resource_report].sort_by { |k,v| k[:name] }
    shared_resources = shared_resources.sort_by { |k,v| k[:name] }
    bench_resources = bench_resources.sort_by { |k,v| k[:name] }
    @report[:resource_report].append({blank_row: true})
    shared_resources.append({blank_row: true})
    @report[:resource_report] = @report[:resource_report] + shared_resources + bench_resources
    @report[:project_wise_resource_report] = @report[:project_wise_resource_report].sort_by { |k,v| k[:project] }
    @report
  end

  def is_shared_resource?(user)
    UI_UX_DESIGNATION.include?(user.designation.try(:name)) ||
    @devops_engg.include?(user.id) ||
    @shared_resource_designations.include?(user.designation.try(:name))
  end

  def get_project_names(user)
    project_ids = user.user_projects.where(
      active: true,
      :allocation.gt => 0
    ).pluck(:project_id)

    Project.where(
      :id.in => project_ids,
      is_active: true
    ).pluck(:name)
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
      @report[:project_wise_resource_report] << add_project_wise_record(user).merge(
        "#{allocation_type}": allocation,
        project: user_project.project.name
      )
    end
  end

  def add_resource_record(user)
    {
      name: get_name(user),
      location: user.location,
      designation: user.designation.try(:name),
      total_allocation: 0,
      billable: 0,
      non_billable: 0,
      investment: 0,
      shared: 0,
      bench: 0,
      technical_skills: user.public_profile.try('technical_skills').slice(0,3),
      projects: get_project_names(user)
    }
  end

  def add_project_wise_record(user)
    {
      name: get_name(user),
      location: user.location,
      designation: user.designation.try(:name),
      billable: 0,
      non_billable: 0,
      investment: 0,
      project: ''
    }
  end

  def get_name(user)
    user.role == ROLE[:consultant] ? "#{user.name} JC" : user.name
  end

  def load_projects
    @report = {
      resource_report: [],
      project_wise_resource_report: []
    }

    devops_project = Project.where(name: 'DevOps Work').first

    @devops_engg = UserProject.where(
      project_id: devops_project.id,
      active: true
    ).pluck(:user_id)

    @shared_resource_designations = [
      'Project Manager',
      'Delivery Head',
      'Delivery Manager',
      'Team Lead',
      'QA Lead',
      'Technical Manager',
      'Senior Technical Manager'
    ]

    exclude_designations = [
      'Assistant Vice President - Sales',
      'Business Development Executive',
      'Office Assistant',
      'Assistant Manager - Accounts',
      'Director'
    ]

    @exclude_designations_ids = Designation.where(
      :name.in => exclude_designations
    ).pluck(:id)

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
