class EmployeeDetail
  include Mongoid::Document

  embedded_in :user

  field :employee_id, type: String
  field :date_of_relieving, :type => Date
  field :notification_emails, type: Array
  field :available_leaves, type: Integer, default: 0

  validates :employee_id, uniqueness: true
  validates :available_leaves, numericality: {greater_than_or_equal_to: 0}

  before_save do 
    self.notification_emails.try(:reject!, &:blank?)
  end

  def deduct_available_leaves(number_of_days)
    remaining_leaves = available_leaves - number_of_days
    self.update_attribute(:available_leaves, remaining_leaves)
  end

  def add_rejected_leave(number_of_days)
    remaining_leaves = available_leaves + number_of_days
    self.update_attribute(:available_leaves, remaining_leaves)
  end
end
