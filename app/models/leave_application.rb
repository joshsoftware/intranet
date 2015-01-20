class LeaveApplication
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable  

  belongs_to :user
  #has_one :address

  field :start_at,        type: Date
  field :end_at,          type: Date
  field :contact_number,  type: Integer
  field :number_of_days,  type: Integer
  #field :approved_by,     type: Integer
  field :reason,          type: String
  field :reject_reason,   type: String
  field :leave_status,    type: String, default: "Pending"
  track_history

  LEAVE_STATUS = ['Pending', 'Approved', 'Rejected']

  validates :start_at, :end_at, :contact_number, :reason, :number_of_days, :user_id , presence: true 
  validates :contact_number, numericality: {only_integer: true}, length: {is: 10}
  validate :validate_available_leaves, on: [:create, :update]
  validate :validate_leave_status, on: :update
  validate :end_date_less_than_start_date, if: 'start_at.present?'

  after_create :deduct_available_leave_send_mail
  after_update :update_available_leave_send_mail, if: "pending?"

  scope :pending, ->{where(leave_status: 'Pending')}
  scope :processed, ->{where(:leave_status.ne => 'Pending')}
 
  def process_after_update(status)
    send("process_#{status}") 
  end
 
  def pending?
    leave_status == 'Pending'
  end

  def process_reject_application
    user = self.user
    user.employee_detail.add_rejected_leave(number_of_days)    
    UserMailer.delay.reject_leave(self.id)
  end

  def process_accept_application
    UserMailer.delay.accept_leave(self.id)
  end

  def self.process_leave(id, leave_status, call_function, reject_reason = '')
    leave_application = LeaveApplication.where(id: id).first
    leave_application.update_attributes({leave_status: leave_status, reject_reason: reject_reason})
    if leave_application.errors.blank?
      leave_application.send(call_function) 
      return {type: :notice, text: "#{leave_status} Successfully"}
    else
      return {type: :error, text: leave_application.errors.full_messages.join(" ")}
    end
  end

  private
    def deduct_available_leave_send_mail
      user = self.user
      user.employee_detail.deduct_available_leaves(number_of_days)    
      user.sent_mail_for_approval(self.id) 
    end

    def update_available_leave_send_mail
      user = self.user
      prev_days, changed_days = number_of_days_change ? number_of_days_change : number_of_days
      user.employee_detail.add_rejected_leave(prev_days)
      user.employee_detail.deduct_available_leaves(changed_days||prev_days)
      user.sent_mail_for_approval(self.id) 
    end


    def validate_available_leaves
      available_leaves = self.user.employee_detail.available_leaves
      errors.add(:base, 'Not Sufficient Leave! Contact Administrator ') if available_leaves < number_of_days
    end

    def validate_leave_status
      if ["Rejected", "Approved"].include?(self.leave_status_was) && ["Rejected", "Approved"].include?(self.leave_status)
        errors.add(:base, 'Leave is already processed')
      end  
    end

    def end_date_less_than_start_date
      if end_at < start_at
        errors.add(:end_at, 'should not be less than start date.')
      end
    end
end
