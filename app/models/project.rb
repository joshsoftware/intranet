class Project
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps
  include ActsAsList::Mongoid

  mount_uploader :image, FileUploader
  mount_uploader :case_study, FileUploader
  mount_uploader :logo, FileUploader

  field :name
  field :code_climate_id
  field :code_climate_snippet
  field :code_climate_coverage_snippet
  field :is_active, type: Boolean, default: true
  field :start_date, type: Date
  field :end_date, type: Date
  field :image
  field :description
  field :url
  field :case_study, type: String
  field :logo
  field :visible_on_home_page, type: Boolean, default: false
  field :visible_on_website, type: Boolean, default: true
  # More Details
  field :ruby_version
  field :rails_version
  field :database
  field :database_version
  field :deployment_server
  field :deployment_script
  field :web_server
  field :app_server
  field :payment_gateway
  field :image_store
  field :index_server
  field :background_jobs
  field :sms_gateway
  field :other_frameworks
  field :other_details

  field :code, type: String
  field :number_of_employees, type: Integer
  field :invoice_date, type: Date

  field :display_name
  field :is_free, type: Boolean, default: false
  field :timesheet_mandatory, type: Boolean, default: true
  slug :name

  has_many :time_sheets, dependent: :destroy
  has_many :user_projects
  accepts_nested_attributes_for :user_projects
  belongs_to :company
  has_and_belongs_to_many :managers, class_name: 'User', foreign_key: 'manager_ids', inverse_of: :managed_projects
  validates_presence_of :name
  validate :project_code

  scope :all_active, ->{where(is_active: true).asc(:name)}
  scope :visible_on_website, -> {where(visible_on_website: true)}
  scope :sort_by_position, -> { asc(:position)}

  attr_accessor :allocated_employees, :manager_name, :employee_names
  # validates_uniqueness_of :code, allow_blank: true, allow_nil: true

  MANERIAL_ROLE = ['Admin', 'Manager']
  validates :display_name, format: { with: /\A[ ]*[\S]*[ ]*\Z/, message: "Name should not contain white space" }
  before_save do
    if name_changed? && display_name.blank?
      self.display_name = name.split.join('_')
    else
      self.display_name = self.display_name.try(:strip)
    end
  end


  after_update do
    Rails.cache.delete('views/website/portfolio.json') if updated_at_changed?
  end

  def self.get_all_sorted_by_name
    Project.all.asc(:name)
  end

  def tag_name(field)
    case field
      when :ruby_version
        "Ruby " + self.ruby_version if ruby_version.present?
      when :rails_version
        "Rails " + rails_version if rails_version.present?
      when :other_frameworks
        self.try(field).split(',')
      when :other_details
        self.try(field).split(',')
      when :database
       "#{self.database} " + self.try(:database_version).to_s
      else
        self.try(field)
    end
  end

  def tags
    tags = []
    [:ruby_version, :rails_version, :database,:deployment_server, :deployment_script, :web_server, :app_server,
      :payment_gateway, :image_store, :background_jobs, :other_frameworks, :other_details].each do |field|
       tags << self.tag_name(field) if self.try(field).present?
    end
    tags.compact.flatten
  end

  def self.to_csv(options = {})
    column_names = ['name', 'code_climate_id', 'code_climate_snippet', 'code_climate_coverage_snippet', 'is_active', 'is_free', 'start_date', 'end_date', 'manager_name', 'number_of_employees', 'allocated_employees', 'employee_names', 'ruby_version', 'rails_version', 'database', 'database_version', 'deployment_server', 'deployment_script', 'web_server', 'app_server', 'payment_gateway', 'image_store', 'index_server', 'background_jobs', 'sms_gateway', 'other_frameworks', 'other_details']
    CSV.generate(options) do |csv|
      csv << column_names.collect(&:titleize)
      all.each do |project|
        project[:is_free] = project[:is_free] == false ? 'No' : 'Yes'
        project[:allocated_employees] = project.users.count
        project[:manager_name] = manager_names(project)
        project[:employee_names] = employee_names(project)
        csv << project.attributes.values_at(*column_names)
      end
    end
  end

  def self.manager_names(project)
    manager_names = []
    project.managers.each do |manager|
      manager_names << manager.name
    end
    manager_names.join(' | ')
  end

  def self.employee_names(project)
    employee_names = []
    project.users.each do |user|
      employee_names << user.name
    end
    employee_names.join(' | ')
  end

  def project_code
    return true if code.nil?
    project = Project.where(code: self.code).first
    if project.present?
      self.errors.add(:base, "Code already exists") unless
        project.company_id == self.company_id
    end
  end

  def add_or_remove_team_member(params)
    return_value_of_add_team_member = return_value_of_remove_team_member = true
    existing_user_ids = UserProject.where(project_id: id, end_date: nil).pluck(:user_id)
    existing_user_ids.map!(&:to_s)
    ids_for_add_members = params['project']['user_ids'].present? ? params['project']['user_ids'] - existing_user_ids : []
    ids_for_remove_members = params['project']['user_ids'].present? ? existing_user_ids - params['project']['user_ids'] : existing_user_ids
    return_value_of_add_team_member = add_team_member(ids_for_add_members) if ids_for_add_members.present?
    return_value_of_remove_team_member = remove_team_member(ids_for_remove_members) if ids_for_remove_members.present?
    return return_value_of_add_team_member, return_value_of_remove_team_member
  end

  def add_team_member(user_ids)
    return_value = true
    user_ids.each do |user_id|
      return_value = UserProject.create!(user_id: user_id, project_id: id, start_date: DateTime.now, end_date: nil) rescue false  
      if return_value == false
        break
      end
    end
    return_value
  end

  def remove_team_member(user_ids)
    return_value = true
    user_ids.each do |user_id|
      user_project = UserProject.where(user_id: user_id, project_id: id, end_date: nil).first
      return_value = user_project.update_attributes(end_date: DateTime.now) rescue false
      if return_value == false
        break
      end
    end
    return_value
  end

  def self.get_approved_project_between_range(from_date, to_date)
    Project.all_active.where("$or" => [{end_date: nil}, {end_date: {"$gte" => from_date, "$lte" => to_date}}]).pluck(:name, :id)
  end

  def self.approved_manager_and_admin
    User.where("$and" => [status: STATUS[2], "$or" => [{role: MANERIAL_ROLE[0]}, {role: MANERIAL_ROLE[1]}]])
  end

  def users
    user_id = user_projects.where(end_date: nil).pluck(:user_id)
    User.in(id: user_id)
  end
  
  def get_user_projects_from_project(from_date, to_date)
    user_ids = user_projects.where("$or"=>[
      {
        "$and" => [
          {
            :start_date.lte => from_date
          },
          {
            end_date: nil
          }
        ]
      },
      {
        "$and" => [
          {
            :start_date.gte => from_date
          },
          {
            :end_date.lte => to_date
          }
        ]
      },
      {
        "$and" => [
          {
            :start_date.lte => from_date
          },
          {
            :end_date.lte => to_date
          },
          {
            :end_date.gte => from_date
          }
        ]
      },
      {
        "$and" => [
          {
            :start_date.gte => from_date
          },
          {
            :end_date.gte => to_date
          },
          {
            :start_date.lte => to_date
          }
        ]
      },
      {
        "$and" => [
          {
            :start_date.gte => from_date
          },
          {
            end_date: nil
          },
          {
            :start_date.lte => to_date
          }
        ]
      },
      {
        "$and" => [
          {
            :start_date.lte => from_date
          },
          {
            :end_date.gte => to_date
          }
        ]
      }
    ]).pluck(:user_id).uniq
    User.in(id: user_ids).where(status: STATUS[2])
  end
end
