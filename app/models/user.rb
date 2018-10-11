class User
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps
  #model's concern
  include LeaveAvailable
  include UserDetail

  devise :database_authenticatable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauth_providers => [:google_oauth2]
  ROLES = ['Super Admin', 'Admin', 'Manager', 'HR', 'Employee', 'Intern', 'Finance']
  ## Database authenticatable
  field :email,               :type => String, :default => ""
  field :encrypted_password,  :type => String, :default => ""
  field :role,                :type => String, :default => "Employee"
  field :uid,                 :type => String
  field :provider,            :type => String        
  field :status,              :type => String, :default => STATUS[0]
  
  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,      :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String
  field :access_token,       :type => String
  field :expires_at,         :type => Integer
  field :refresh_token,      :type => String
  field :visible_on_website, :type => Boolean, :default => false
  field :website_sequence_number, :type => Integer

  has_many :leave_applications
  has_many :attachments
  has_many :time_sheets
  has_many :user_projects
  has_and_belongs_to_many :schedules
  has_and_belongs_to_many :managed_projects, class_name: 'Project', foreign_key: 'managed_project_ids', inverse_of: :managers

  after_update :delete_team_cache, if: :website_fields_changed?

  accepts_nested_attributes_for :attachments, reject_if: :all_blank, :allow_destroy => true
  validates :email, format: {with: /\A.+@#{ORGANIZATION_DOMAIN}/, message: "Only #{ORGANIZATION_NAME} email-id is allowed."}
  validates :role, :email, presence: true
  validates_associated :employee_detail
  scope :employees, ->{all.asc("public_profile.first_name")}
  scope :approved, ->{where(status: 'approved')}  
  scope :visible_on_website, -> {where(visible_on_website: true)}
  scope :interviewers, ->{where(:role.ne => 'Intern')}
  #Public profile will be nil when admin invite user for sign in with only email address 
  delegate :name, to: :public_profile, :allow_nil => true

  before_create do
    self.website_sequence_number = (User.max(:website_sequence_number) || 0) + 1
  end


  slug :name
  # Hack for Devise as specified in https://github.com/plataformatec/devise/issues/2949#issuecomment-40520236
  def self.serialize_into_session(record)
    [record.id.to_s, record.authenticatable_salt]
  end

  def sent_mail_for_approval(leave_application_id)
    notified_users = [
                      User.approved.where(role: 'HR').pluck(:email), User.approved.where(role: 'Admin').first.try(:email),
                      self.employee_detail.try(:notification_emails).try(:split, ',')
                     ].flatten.compact.uniq
    UserMailer.delay.leave_application(self.email, notified_users, leave_application_id)
  end
  def role?(role)
    self.role == role
  end
 
  def can_edit_user?(user)
    (["HR", "Admin", "Finance", "Manager", "Super Admin"].include?(self.role)) || self == user 
  end
  
  def can_download_document?(user, attachment)
    user = user.nil? ? self : user
    (["Admin", "Finance", "Manager", "Super Admin"].include?(self.role)) || attachment.user_id == user.id
  end

  def can_change_role_and_status?(user)
    return true if (["Admin", "Super Admin"]).include?(self.role)
    return true if self.role?("HR") and self != user
    return false
  end

  def allow_in_listing?
    return true if self.status == 'approved'
    return false
  end

  def set_details(dobj, value)
    unless value.nil?
      set("#{dobj}_day" => value.day)
      set("#{dobj}_month" => value.month)
    end
  end

  def website_fields_changed?
    website_sequence_number_changed? || visible_on_website_changed?
  end

  def generate_errors_message
    error_msg = []
    error_msg.push(errors.full_messages,
                   public_profile.errors.full_messages,
                   private_profile.errors.full_messages)
    error_msg.join(' ')
  end

  def add_or_remove_projects(params)
    return_value_of_add_project = return_value_of_remove_project = true
    existing_project_ids = UserProject.where(user_id: id, end_date: nil).pluck(:project_id)
    existing_project_ids.map!(&:to_s)
    params[:user][:project_ids].shift
    ids_for_add_project = params[:user][:project_ids].present? ? params[:user][:project_ids] - existing_project_ids : []
    ids_for_remove_project = params[:user][:project_ids].present? ? existing_project_ids - params[:user][:project_ids] : existing_project_ids
    return_value_of_add_project = add_projects(ids_for_add_project) if ids_for_add_project.present?
    return_value_of_remove_project = remove_projects(ids_for_remove_project) if ids_for_remove_project.present?
    return return_value_of_add_project, return_value_of_remove_project
  end

  def add_projects(project_ids)
    return_value = true
    project_ids.each do |project_id|
      return_value = UserProject.create!(user_id: id, project_id: project_id, start_date: DateTime.now, end_date: nil) rescue false
      if return_value == false
        break
      end
    end
    return_value
  end

  def remove_projects(project_ids)
    return_value = true
    project_ids.each do |project_id|
      user_project = UserProject.where(user_id: id, project_id: project_id, end_date: nil).first
      return_value = user_project.update_attributes!(end_date: DateTime.now) rescue false
      if return_value == false
        break
      end
    end
    return_value
  end

  def project_ids
    project_ids = user_projects.where(end_date: nil).pluck(:project_id)
  end

  def worked_on_projects(from_date, to_date)
    project_ids = time_sheets.where(:date.gte => from_date, :date.lte => to_date).pluck(:project_id).uniq
    Project.in(id: project_ids)
  end

  def projects
    project_ids = user_projects.where(end_date: nil).pluck(:project_id)
    Project.in(id: project_ids)
  end
  
  def get_user_projects_from_user(project_id, from_date, to_date)
    user_projects.where("$and"=>[
        {
          "$or" => [
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
          ]
        },
        {
          project_id: project_id
        }
      ])
  end
end
