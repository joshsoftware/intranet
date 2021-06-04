class UserProject
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_date, type: Date
  field :end_date, type: Date, default: nil
  field :time_sheet, type: Boolean, default: false
  field :active, type: Boolean, default: true
  field :allocation, type: Integer, default: 160
  field :billable, type: Boolean, default: true

  belongs_to :user
  belongs_to :project

  validates :user_id, :project_id, :active, :allocation, presence: true
  validates :user_id, uniqueness: {scope: :project_id}, if: :active_user?
  validates :allocation, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0, less_than_or_equal_to: 160,
      message: 'not less than 0 & not more than 160'
  }
  validate :custom_validations, if: 'project.try(:end_date)'

  def custom_validations
    errors.add(:start_date, "can't be blank") if start_date.nil?
    errors.add(:end_date, "can't be blank") if end_date.nil?
    return if self.errors.present?
    if end_date.present?
      start_date_less_than_end_date
      start_date_and_end_date
      validate_end_date
    end
  end

  scope :approved_users, ->{where(:user_id.in => User.approved.pluck(:id))}
  scope :active_users, ->{where(:user_id.in => User.approved.pluck(:id), active: true)}
  scope :inactive_users, ->{where(:user_id.in => User.approved.pluck(:id), active: false)}
  scope :ex_users, ->{where(:user_id.nin => User.approved.pluck(:id))}
  scope :inactive_and_ex_users, ->{where(active: false)}

  before_save do
    self.end_date = project.end_date if end_date.nil? && project.end_date.present?
  end

  after_save :call_monitor_service, if: 'active_changed?'

  def validate_end_date
    errors.add(:end_date, 'should not be greater than project end date') if end_date > project.end_date
  end

  def start_date_less_than_end_date
    if end_date < start_date
      errors.add(:end_date, 'should not be less than start date.')
    end
  end

  def start_date_and_end_date
    if start_date < project.start_date
      errors.add(:start_date, 'should not be less than project start date.')
    end
    if end_date < project.start_date
      errors.add(:end_date, 'should not be less than project start date.')
    end
  end

  def call_monitor_service
    CodeMonitoringWorker.perform_async(monitor_service_params)
  end

  def monitor_service_params
    if active
      {
        event_type: 'User Added',
        user_id: user_id.to_s,
        project_id: project_id.to_s
      }
    else
      {
        event_type: 'User Removed',
        user_id: user_id.to_s,
        project_id: project_id.to_s
      }
    end
  end
end

def active_user?
  UserProject.where(project_id: project_id, user_id: user_id).pluck(:active).inject do |final_user_active, current_user_active|
     final_user_active || current_user_active
  end
end
