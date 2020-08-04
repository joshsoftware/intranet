class EmployeeDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include UserDetail
  DESIGNATION_TRACKS = ['Software Engineer', 'QA Engineer', 'UI/UX Designer']
  embedded_in :user

  field :employee_id, type: String
  field :date_of_relieving, :type => Date
  field :notification_emails, type: Array
  field :available_leaves, type: Integer, default: 0
  field :description
  field :is_billable, type: Boolean, default: false
  field :designation_track, type: String, default: DESIGNATION_TRACKS.first
  field :location

  belongs_to :designation

  validates :employee_id, uniqueness: true
  #validates :employee_id, numericality: {greater_than_or_equal_to: 9000}, if: :assign_new_usa_id?
  #validates :designation_track, presence: true
  validates :available_leaves, numericality: {greater_than_or_equal_to: 0}
  after_update :delete_team_cache, if: Proc.new{ updated_at_changed? }
  validates :location, presence: true

  before_save do
    self.notification_emails.try(:reject!, &:blank?)
  end


  def deduct_available_leaves(number_of_days)
    remaining_leaves = available_leaves - number_of_days
    self.update_attribute(:available_leaves, remaining_leaves)
  end

  def get_notification_emails
    unapproved_employees = User.where(:status.ne => 'approved').pluck(:email)
    notification_emails - unapproved_employees
  end

  def add_rejected_leave(number_of_days)
    remaining_leaves = available_leaves + number_of_days
    self.update_attribute(:available_leaves, remaining_leaves)
  end

  def assign_new_usa_id?
    # For Sachin's record we are keeping his employee ID as it is
    # For all other USA employees ID must be above 9000
    employee_id.nil? and location == "Plano" ? true : false
  end
end
