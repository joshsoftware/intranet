class UserProject
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_date, type: Date
  field :end_date, type: Date, default: nil
  field :time_sheet, type: Boolean, default: false
  field :active, type:Boolean, default: true
  field :allocation, type: Integer, default: 100

  belongs_to :user
  belongs_to :project

  validates :user_id, :project_id, :start_date, :active, :allocation, presence: true
  validates :user_id, uniqueness: {scope: :project_id}, if: :active_user?
  validates :allocation, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1, less_than_or_equal_to: 100,
      message: 'should be between range of 1-100'
  }


  validates :end_date, presence: {unless: "!!active || active.nil?", message: "is mandatory to mark inactive"}
  validate :start_date_less_than_end_date, if: 'end_date.present?'

  scope :approved_users, ->{where(:user_id.in => User.approved.pluck(:id))}
  scope :active_users, ->{where(:user_id.in => User.approved.pluck(:id), :active => true)}
  scope :inactive_users, ->{where(:user_id.in => User.approved.pluck(:id), :active => false)}
  scope :ex_users, ->{where(:user_id.nin => User.approved.pluck(:id))}

  def start_date_less_than_end_date
    if end_date < start_date
      errors.add(:end_date, 'should not be less than start date.')
    end
  end
end

def active_user?
  UserProject.where(project_id: project_id, user_id: user_id).pluck(:active).inject do |final_user_active, current_user_active|
     final_user_active || current_user_active
  end
end
