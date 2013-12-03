class User
  include Mongoid::Document
  include Mongoid::Slug
  
  #model's concern
  include LeaveAvailable
  include UserDetail 

  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauth_providers => [:google_oauth2]
  ROLES = ['Admin', 'Manager', 'HR', 'Employee', 'Intern', 'Finance']
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
    
  has_many :leave_applications
  has_many :attachments
  has_and_belongs_to_many :projects
  
  accepts_nested_attributes_for :attachments, reject_if: :all_blank, :allow_destroy => true
  validates :email, format: {with: /\A.+@joshsoftware.com/, message: "Only Josh email-id is allowed."}
  validates :role, :email, presence: true
  validates_associated :employee_detail

  scope :employees, all.asc("public_profile.first_name")
  scope :approved, where(status: 'approved')  
  #Public profile will be nil when admin invite user for sign in with only email address 
  delegate :name, to: :public_profile, :allow_nil => true
  slug :name do|u|
    u.name.try(:to_url) || u.id.to_s   
  end

  def sent_mail_for_approval(leave_application_id)
    notified_users = [
                      User.find_by(role: 'HR').email, User.find_by(role: 'Admin').try(:email),
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
    (["HR", "Admin", "Finance", "Manager", "Super Admin"].include?(self.role)) || attachment.user_id == user.id
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
end
