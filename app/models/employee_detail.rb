class EmployeeDetail
  include Mongoid::Document

  embedded_in :user

  field :employee_id, type: String
  field :date_of_relieving, :type => Date
  field :notification_emails, type: Array
  
  validates :employee_id, uniqueness: true 
  before_save do 
    self.notification_emails.try(:reject!, &:blank?)
  end
end
