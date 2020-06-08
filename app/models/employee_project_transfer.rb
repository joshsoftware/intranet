class EmployeeProjectTransfer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :requested_date,        type: Date
  field :requested_by
  field :request_for
  field :from_project
  field :to_project
  field :allocation,            type: Integer,  default: 100
  field :request_reason,        type: String
  field :start_date,            type: Date
  field :end_date,              type: Date,     default: nil
  field :status,                type: String,   default: PENDING

  validates :requested_date, :request_for, :requested_by, :start_date,
            :from_project, :request_reason, :to_project, :allocation, presence: true
  validates :allocation, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1, less_than_or_equal_to: 100,
    message: 'should be between range of 1-100'
  }
  validate :validate_start_end_date, if: 'end_date.present?'
  validate :validate_user_from_project
  validate :validate_user_to_project
  validate :validate_duplicate_from_projects      #validating if from_project request is already pending or approved

  scope :pending, ->{where(status: PENDING)}
  scope :processed, ->{where(:status.ne => PENDING)}
  scope :approved, -> { where(status: APPROVED)}

  after_save :send_request_mail, if: "pending?"

  def validate_start_end_date
    if end_date < start_date
      errors.add(:end_date, 'should not be less than start date.')
    end
  end

  def send_request_mail
    if pending?
      EmployeeProjectTransferMailer.delay.employee_project_transfer_request(self.id)
    end
  end

  def pending?
    self.status == PENDING
  end

  def process_request(perform_action)
    if perform_action == APPROVED
      self.update_attributes({status: APPROVED})
      if self.save
        EmployeeProjectTransferMailer.delay.accept_transfer_request(self.id)
        message = {type: :notice, text: "Employee Project Transfer Request approved Successfully"}
      else
        message = @message = {type: :error, text: "Employee Project Transfer request cannot be processed " + self.errors.full_messages.join(",")}
      end
    else
      self.update_attributes({status: REJECTED})
      if self.save
        EmployeeProjectTransferMailer.delay.reject_transfer_request(self.id)
        message = {type: :notice, text: "Employee Project Transfer Request approved Successfully"}
      else
        message = @message = {type: :error, text: "Employee Project Transfer request cannot be processed " + self.errors.full_messages.join(",")}
      end
    end
    message
  end

  def validate_user_from_project
    user = User.find(request_for)
    if user.projects.pluck(:id).collect(&:to_s).include?(from_project) == false
      errors.add(:from_project, 'requested employee is not in given from project.')
    end
  end

  def validate_user_to_project
    user = User.find(request_for)
    if user.projects.pluck(:id).collect(&:to_s).include?(to_project)
      errors.add(:to_project, 'requested employee is already in to project.')
    end
  end

  def validate_duplicate_from_projects
    employee_project_transfer_requests = EmployeeProjectTransfer.where(:id.ne => self.id, request_for: self.request_for, from_project: self.from_project, :status.ne => REJECTED).first
    if employee_project_transfer_requests.nil? == false
      errors.add(:from_project, 'the unrejected request for candidate from project is already present')
    end
  end
end
