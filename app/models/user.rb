class User
  include Mongoid::Document
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauth_providers => [:google_oauth2]
  ROLES = ['Admin', 'Manager', 'HR', 'Employee']
  ## Database authenticatable
  field :email,               :type => String, :default => ""
  field :encrypted_password,  :type => String, :default => ""
  field :role,                :type => String, :default => ""
  field :uid,                 :type => String
  field :provider,            :type => String        
  field :status,              :type => String, :default => STATUS[0]

  ## Recoverable
  field :reset_password_token,   :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,      :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  embeds_one :public_profile#, :cascade_callbacks => true
  embeds_one :private_profile
  embeds_one :employee_detail

  has_many :leave_details
  has_many :leave_applications
  has_many :attachments

  accepts_nested_attributes_for :private_profile, reject_if: :all_blank, allow_destroy: true 
  accepts_nested_attributes_for :public_profile, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :employee_detail, :attachments, :allow_destroy => true

  validates :email, format: {with: /\A.+@joshsoftware.com/, message: "Only Josh email-id is allowed."}
  validates :role, :email, presence: true

  def self.from_omniauth(auth)
    if auth.info.email.include? "joshsoftware.com"
    
      user = User.where(email: auth.info.email).first
      unless user
        user = User.create(provider: auth.provider, uid: auth.uid, email: auth.info.email, password: Devise.friendly_token[0,20])
        user.build_public_profile(first_name: auth.info.first_name, last_name: auth.info.last_name).save
      else
        user.build_public_profile(first_name: auth.info.first_name, last_name: auth.info.last_name).save
        user.update_attributes(provider: auth.provider, uid: auth.uid)
      end
      user
    else
      false
    end
  end

  def role?(role)
    self.role == role
  end
end
