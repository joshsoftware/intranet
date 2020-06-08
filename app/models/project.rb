class Project
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps
  include ActsAsList::Mongoid

  mount_uploader :image, FileUploader
  mount_uploader :case_study, FileUploader
  mount_uploader :logo, FileUploader

  BILLING_FREQUENCY_TYPES = ['Monthly', 'Bi-weekly', 'Adhoc', 'NA'].freeze
  TYPE_OF_PROJECTS = ['T&M', 'Fixbid', 'Free', 'Investment'].freeze

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
  field :timesheet_mandatory, type: Boolean, default: true
  field :billing_frequency
  field :type_of_project
  field :is_activity, type: Boolean, default: false
  field :domains, type: Array, default: []
  slug :name

  has_many :technology_details
  accepts_nested_attributes_for :technology_details, allow_destroy: true, reject_if: :technology_details_record_is_blank?
  has_many :time_sheets, dependent: :destroy
  has_many :user_projects, dependent: :destroy
  has_many :repositories, dependent: :destroy
  accepts_nested_attributes_for :repositories, allow_destroy: true
  accepts_nested_attributes_for :user_projects, allow_destroy: true
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
  validates :start_date, :billing_frequency, :type_of_project, presence: true
  validates_presence_of :end_date, unless: -> { is_active? }
  validates :billing_frequency, inclusion: { in: BILLING_FREQUENCY_TYPES, allow_nil: true }
  validates :type_of_project, inclusion: { in: TYPE_OF_PROJECTS, allow_nil: true }
  before_save do
    if name_changed? && display_name.blank?
      self.display_name = name.split.join('_')
    else
      self.display_name = self.display_name.try(:strip)
    end
  end

  after_save :update_user_projects, unless: -> { is_active? }

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
    column_names = ['name', 'code_climate_id', 'code_climate_snippet',
      'code_climate_coverage_snippet','is_active', 'start_date', 'end_date',
      'manager_name', 'number_of_employees', 'allocated_employees', 'employee_names',
      'ruby_version', 'rails_version', 'database', 'database_version', 'deployment_server',
      'deployment_script', 'web_server', 'app_server', 'payment_gateway', 'image_store',
      'index_server', 'background_jobs', 'sms_gateway', 'other_frameworks', 'other_details']
    CSV.generate(options) do |csv|
      csv << column_names.collect(&:titleize)
      all.map do |project|
        project.allocated_employees = project.users.count
        project.manager_name        = manager_names(project)
        project.employee_names      = employee_names(project)
        csv << project.attributes.values_at(*column_names)
      end;nil
    end
  end

  def self.team_data_to_csv
    unwanted_project_names = ['Interview',  'Other']
    unwanted_projects = Project.where(:name.in => unwanted_project_names)
    projects = Project.where(:id.nin => unwanted_projects.pluck(:id)).all_active.order_by(name: :asc)

    file = CSV.generate do |csv|
      csv << [
        'Project',
        'Project Start Date',
        'Project End Date',
        'Employee Name',
        'Employee Tech Skills',
        'Employee Other Skills',
        'Employee Total Exp in Months',
        'Employee Started On Project At',
        'Days on Project'
      ]
      projects.each do |project|
        end_date = project.end_date.blank? ? (Date.today + 6.months).end_of_month : project.end_date
        user_ids = UserProject.where(project_id: project.id, :end_date => nil).pluck(:user_id).uniq
        users = User.approved.order_by("public_profile.first_name" => :asc)
        users.each do |user|
          up = UserProject.where(project_id: project.id, user_id: user.id, :end_date => nil).first
          csv << [
            project.name,
            project.start_date,
            end_date,
            user.name,
            [user.public_profile.try(:technical_skills)].flatten.compact.uniq.sort.reject(&:blank?).join(', ').delete("\n").gsub("\r", ' '),
            user.try(:public_profile).try(:skills).split(',').flatten.compact.uniq.sort.reject(&:blank?).join(', ').delete("\n").gsub("\r", ''),
            user.experience_as_of_today,
            up.start_date,
            (Date.today - up.start_date).to_i
          ] if up
        end
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
    project = Project.where(code: self.code, :id.ne => self.id).first
    if project.present?
      self.errors.add(:base, "Code already exists") unless
        project.company_id == self.company_id
    end
  end

  # these methods were used to add managers as team members but it had a bug
  # def add_or_remove_team_members(user_ids)
  #   user_ids = user_ids.presence ? user_ids.collect!(&:to_s) : []
  #   existing_member_ids = user_projects.where(end_date: nil).pluck(:user_id).collect(&:to_s)
  #   new_member_ids = user_ids.present? ? user_ids - existing_member_ids : []
  #   removed_member_ids = user_ids.present? ? existing_member_ids - user_ids : []
  #   add_team_members(new_member_ids) if new_member_ids.present?
  #   remove_team_members(removed_member_ids) if removed_member_ids.present?
  # end
  #
  # def add_team_members(user_ids)
  #   user_ids.each do |user_id|
  #     user_projects.create!(user_id: user_id, start_date: DateTime.now, end_date: nil)
  #   end
  # end
  #
  # def remove_team_members(user_ids)
  #   user_ids.each do |user_id|
  #     user_project = user_projects.where(user_id: user_id, end_date: nil).first
  #     user_project.update_attributes(end_date: DateTime.now, active: false) if user_project
  #   end
  # end

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

  private

  def update_user_projects
    user_projects.each { |user_project| user_project.update_attributes(end_date: end_date) }
  end

  def technology_details_record_is_blank?(attributes)
    attributes[:name].blank?  and attributes[:version].blank?
  end
end
