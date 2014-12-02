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
  validate :validate_leave_details, on: :create
  validate :validate_leave_status, on: :update
  validate :validate_leave_details_on_update, on: :update
  validate :end_date_less_than_start_date, if: 'start_at.present?'

  after_create :deduct_available_leave_send_mail
  after_update :update_available_leave_send_mail, if: "pending?"

  scope :pending, ->{where(leave_status: 'Pending')}
  scope :processed, ->{where(:leave_status.ne => 'Pending')}
 
  def require_medical_certificate?
    leave_type.name == 'Sick' and number_of_days >= 3
  end

  def process_after_update(status)
    send("process_#{status}") 
  end
 
  def pending?
    leave_status == 'Pending'
  end

  def process_reject_application
    user = self.user
    user.get_leave_detail(Date.today.year).add_rejected_leave(leave_type: self.leave_type.name, no_of_leave: self.number_of_days)    
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
      user.get_leave_detail(Date.today.year).deduct_available_leave(leave_type: self.leave_type.name, no_of_leave: self.number_of_days)    
      user.sent_mail_for_approval(self.id) 
    end

    def update_available_leave_send_mail
      user = self.user
      prev_days, changed_days = number_of_days_change ? number_of_days_change : number_of_days
      prev_type, changed_type = changed_leave_type
      user.get_leave_detail(Date.today.year).add_rejected_leave(leave_type: prev_type.name, no_of_leave: prev_days)
      user.get_leave_detail(Date.today.year).deduct_available_leave(leave_type: changed_type.name, no_of_leave: changed_days||prev_days)
      user.sent_mail_for_approval(self.id) 
    end

    def changed_leave_type
      prev_type_id, changed_type_id = leave_type_id_change ? leave_type_id_change : leave_type_id
      [LeaveType.find(prev_type_id), LeaveType.find(changed_type_id || leave_type_id)]
    end

    def validate_leave_details_on_update
      if number_of_days_change or leave_type_id_change
      prev_days, changed_days = number_of_days_change ? number_of_days_change : number_of_days
      prev_type, changed_type = changed_leave_type
      if leave_type_id_change
        validate_leave_details(changed_type.name, changed_days || number_of_days)
      else
        validate_leave_details(changed_type.name, (changed_days || number_of_days) - prev_days)
      end
      end
    end

    def validate_leave_details(name = leave_type.name, days = number_of_days)
      leave_detail = self.user.leave_details.where(year: Date.today.year).first
      if leave_detail.blank? or leave_detail.validate_leave(name, days) 
        errors.add(:base, 'Not Sufficient Leave !Contact Administrator ') 
      end
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
