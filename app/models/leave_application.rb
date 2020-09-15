class LeaveApplication
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  belongs_to :user
  #has_one :address

  LEAVE = 'LEAVE'
  WFH = 'WFH'

  LEAVE_TYPES = [LEAVE, WFH]

  field :start_at,        type: Date
  field :end_at,          type: Date
  field :contact_number,  type: Integer
  field :number_of_days,  type: Integer
  field :processed_by
  field :reason,          type: String
  field :leave_type,      type: String, default: LEAVE

  # We were accepting reason only on rejection so field named as reject_reason
  # but now we accept reason 1) For rejection and 2) For approval after rejection
  # If we wish to change field name add another field
  # copy values from reject_reason to this new field on production and once run successfully
  # Remove this field
  field :reject_reason,   type: String

  field :leave_status,    type: String, default: PENDING
  track_history

  validates :start_at, :end_at, :contact_number, :reason, :number_of_days, :user_id, :leave_type, presence: true
  validates :leave_type, inclusion: { in: LEAVE_TYPES }
  validates :contact_number, numericality: {only_integer: true}, length: {is: 10}
  validate :validate_available_leaves, on: [:create, :update]
  validate :end_date_less_than_start_date, if: 'start_at.present?'
  validate :validate_date, on: [:create, :update]

  after_save :deduct_available_leave_send_mail
  after_update :update_available_leave_send_mail, if: "pending?"

  scope :pending, ->{where(leave_status: PENDING)}
  scope :processed, ->{where(:leave_status.ne => PENDING)}
  scope :unrejected, -> { where(:leave_status.ne => REJECTED )}

  attr_accessor :sanctioning_manager

  def leave_request?
    leave_type == LEAVE
  end

  def leave_count
    (self.end_at - self.start_at).to_i + 1
  end

  def process_after_update(status)
    send("process_#{status}")
  end

  def pending?
    leave_status == PENDING
  end

  def processed?
    # Currently we have only three status (Approved, Rejected, Pending)
    # so processed means !pending i.e. Approved or Rejected
    leave_status != PENDING
  end

  def approved?
    leave_status == APPROVED
  end

  def processed_by_name
    User.where(id: self.processed_by).first.try(:name)
  end

  def process_reject_application
    if leave_request?
      user = self.user
      user.employee_detail.add_rejected_leave(number_of_days)
    end
    UserMailer.delay.reject_leave(self.id)
  end

  def process_accept_application
    UserMailer.delay.accept_leave(self.id)
    send_leave_notification
  end

  def send_leave_notification
    if start_at >= Date.today && leave_request?
      emails = get_team_members
      UserMailer.send_accept_leave_notification(id, emails).deliver_now!
    end
  end

  def get_team_members
    emails = []
    project_ids = self.user.project_details
    project_ids.each do |project_id|
      project = Project.where(id: project_id[:id]).first
      emails << project.users.pluck(:email)
    end
    emails = emails.flatten.uniq
  end

  def self.process_leave(id, leave_status, call_function, reject_reason = '', processed_by)
    leave_application = LeaveApplication.where(id: id).first

    if leave_application.leave_status != leave_status
      reason = [leave_application.reject_reason, reject_reason].select(&:present?).join(';') if leave_application.reject_reason.present? or reject_reason.present?

      leave_application.update_attributes({leave_status: leave_status, reject_reason: reason, processed_by: processed_by})
      if leave_application.errors.blank?
        leave_application.send(call_function)
        return {type: :notice, text: "#{leave_status} Successfully"}
      else
        return {type: :error, text: leave_application.errors.full_messages.join(" ")}
      end
    else
      return {type: :error, text: "#{leave_application.leave_type} is already #{leave_status}"}
    end
  end

  def self.get_leaves_for_sending_reminder(date)
    LeaveApplication.where(start_at: date, leave_status: APPROVED)
  end

  def self.get_users_past_leaves(user_id)
    LeaveApplication.where(
      user_id: user_id,
      start_at: Date.today - 6.month...Date.today,
      leave_status: 'Approved'
    ).order_by(:start_at.desc)
  end

  def self.get_users_upcoming_leaves(user_id)
    LeaveApplication.where(
      user_id: user_id,
      start_at: {'$gt' => Date.today},
      :leave_status.ne => REJECTED
    ).order_by(:start_at.asc)
  end

  def self.pending_leaves_reminder
    count = 0
    date  = Date.today
    while count < 2
      date  += 1
      count += 1 unless HolidayList.is_holiday?(date)
      #checking count for 2 days - sending mail only for 1 and 2 day remaining leaves.
      if count == 1 || 2
        leave_applications = LeaveApplication.where(start_at: date, leave_status: PENDING)
        next if leave_applications.empty?
        leave_applications.each do |leave_application|
          managers = leave_application.user.get_managers_emails
          UserMailer.pending_leave_reminder(leave_application.user, managers, leave_application).deliver_now
        end
      end
    end
  end

  private

  def deduct_available_leave_send_mail
    # Since leave has been deducted on creation, don't deduct leaves
    # if changed from PENDING to APPROVED
    # Deduct on creation and changed from 'Rejected' to 'Approved'
    if (pending? and self.leave_status_was.nil?) or (approved? and self.leave_status_was == REJECTED)
      user = self.user
      user.employee_detail.deduct_available_leaves(number_of_days) if leave_request?
      user.sent_mail_for_approval(self.id) unless self.leave_status_was == REJECTED
    end
  end

  def update_available_leave_send_mail
    user = self.user
    if leave_request?
      prev_days, changed_days = number_of_days_change ? number_of_days_change : number_of_days
      user.employee_detail.add_rejected_leave(prev_days)
      user.employee_detail.deduct_available_leaves(changed_days||prev_days)
    end
    user.sent_mail_for_approval(self.id)
  end


  def validate_available_leaves
    if number_of_days_changed? or (self.leave_status_was == REJECTED and self.leave_status == APPROVED)
      available_leaves = self.user.employee_detail.available_leaves
      available_leaves += number_of_days_change[0].to_i if number_of_days_change.present? and number_of_days_change[1].present?
      errors.add(:base, 'Not Sufficient Leave!') if available_leaves < number_of_days
    end
  end

  def end_date_less_than_start_date
    if end_at < start_at
      errors.add(:end_at, 'should not be less than start date.')
    end
  end

  def validate_date
    if self.start_at_changed? or self.end_at_changed?
      # While updating leave application do not consider self..
      leave_applications = self.user.leave_applications.unrejected.ne(id: self.id)
      leave_applications.each do |leave_application|
        errors.add(:base, "Already applied for LEAVE/WFH on same date") and return if self.start_at.between?(leave_application.start_at, leave_application.end_at) or
          self.end_at.between?(leave_application.start_at, leave_application.end_at) or
          leave_application.start_at.between?(self.start_at, self.end_at) or
          leave_application.end_at.between?(self.start_at, self.end_at)
      end
    end
  end
end
