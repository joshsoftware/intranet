class LeaveApplication
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable  

  belongs_to :user
  belongs_to :leave_type
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

  validates :start_at, :end_at, :contact_number, :reason, :number_of_days, :user_id, :leave_type_id, presence: true 
  validates :contact_number, numericality: {only_integer: true}, length: {is: 10}

  validate :validate_leave_details, on: :create
    
  validate :validate_leave_status, on: :update
 
  after_create :deduct_available_leave_send_mail
  
  def process_after_update(status)
    send("process_#{status}") 
  end
  
  def process_reject_application
    user = self.user
    user.get_leave_detail(Date.today.year).add_rejected_leave(leave_type: self.leave_type.name, no_of_leave: self.number_of_days)    
    UserMailer.delay.reject_leave(self.id)
  end

  def process_accept_application
    UserMailer.delay.accept_leave(self.id)
  end

  def self.process_leave(id, leave_status, call_function)
    leave_application = LeaveApplication.where(id: id).first
    leave_application.leave_status = leave_status 
    leave_application.save
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

    def validate_leave_details
      user = self.user
      if user.leave_details.where(year: Date.today.year).first.validate_leave(self.leave_type.name, self.number_of_days) 
        errors.add(:base, 'Not Sufficient Leave !Contact Administrator ') 
      end
    end

    def validate_leave_status
      if ["Rejected", "Approved"].include?(self.leave_status_was) && ["Rejected", "Approved"].include?(self.leave_status)
        errors.add(:base, 'Leave is already processed')
      end  
    end
end
