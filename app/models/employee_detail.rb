class EmployeeDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include UserDetail
  DESIGNATION_TRACKS = ['Software Engineer', 'QA Engineer', 'UI/UX Designer']

  embedded_in :user

  field :employee_id, type: String
  field :date_of_relieving, type: Date
  field :notification_emails, type: Array, default: []
  field :reason_of_resignation
  field :available_leaves, type: Integer, default: 0
  field :description
  field :is_billable, type: Boolean, default: false
  field :skip_unassigned_project_ts_mail, type: Boolean, default: false
  field :designation_track, type: String, default: DESIGNATION_TRACKS.first
  field :location
  field :source, type: String
  field :division, type: String
  field :joining_bonus_paid, type: Boolean, default: false
  field :assessment_month, type: Array, default: []
  field :assessment_platform

  belongs_to :designation

  validates :employee_id, uniqueness: true
  #validates :designation_track, presence: true
  validates :date_of_relieving, presence: true, if: :user_status_changed?, on: :update
  validates :available_leaves, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 24}
  after_update :delete_team_cache, if: Proc.new{ updated_at_changed? }
  validates :location, presence: true
  validates :division, inclusion: { in: DIVISION_TYPES.values, allow_nil: true }
  validates :assessment_platform, inclusion: { in: ASSESSMENT_PLATFORM }, allow_nil: false, on: :update
  validates :assessment_month, presence: true, if: :eligible_for_assessment?
  validates :assessment_month, length: { is: 2 , message: 'should have two months.'},allow_nil: false, if: :eligible_for_assessment?
  validates :assessment_month, length: { in: 0..2, message:'should have two months.'}, unless: :eligible_for_assessment? 
  
  before_save do
    self.notification_emails.try(:reject!, &:blank?)
  end

  before_validation do
    self.assessment_month.try(:reject!, &:blank?)
  end

  def user_status_changed?
    date_of_relieving.blank? &&
    self.user.status_changed? &&
    self.user.status == STATUS[:resigned]
  end

  def deduct_available_leaves(number_of_days)
    remaining_leaves = available_leaves - number_of_days
    self.update_attribute(:available_leaves, remaining_leaves)
  end

  def get_notification_emails
    User.where(:email.in => notification_emails, status: STATUS[:approved]).pluck(:email)
  end

  def get_notification_names
    User.where(:email.in => notification_emails, status: STATUS[:approved]).collect(&:name)
  end

  def add_rejected_leave(number_of_days)
    remaining_leaves = available_leaves + number_of_days
    self.update_attribute(:available_leaves, remaining_leaves)
  end

  def eligible_for_assessment?
    !(
      user.role.in?([ROLE[:intern], ROLE[:admin]]) ||
      user.employee_detail.assessment_platform == "None" ||
      (user.email =~ /\.jc@joshsoftware\.com$/).present?
    )
  end
end

