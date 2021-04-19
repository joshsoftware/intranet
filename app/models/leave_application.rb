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
  field :processed_by
  field :reason,          type: String
  field :leave_type,      type: String, default: LEAVE_TYPES[:leave]

  # We were accepting reason only on rejection so field named as reject_reason
  # but now we accept reason 1) For rejection and 2) For approval after rejection
  # If we wish to change field name add another field
  # copy values from reject_reason to this new field on production and once run successfully
  # Remove this field
  field :reject_reason,   type: String

  field :leave_status,    type: String, default: PENDING
  track_history

  validates :start_at, :end_at, :contact_number, :reason, :number_of_days, :user_id, :leave_type, presence: true
  validates :leave_type, inclusion: { in: LEAVE_TYPES.values }
  validates :contact_number, numericality: {only_integer: true}, length: {is: 10}
  validate :validate_available_leaves, on: [:create, :update], if: :leave?
  validate :end_date_less_than_start_date, if: 'start_at.present?'
  validate :validate_date, on: [:create, :update], unless: :optional_leave?
  validate :validate_optional_leave, on: [:create, :update], if: 'optional_leave? && !processed?'
  validate :update_leave_count, on: :update, if: :previous_leave_type?

  after_save do
    deduct_available_leave_send_mail
    send_leave_notification
    #below is to update number of days in overlapping leave and
    #available leaves of user if optional leave is created or modified
    adjust_leave_count if optional_leave?
  end

  after_update :update_available_leave_send_mail, if: 'pending?'

  scope :pending, ->{where(leave_status: PENDING)}
  scope :processed, ->{where(:leave_status.ne => PENDING)}
  scope :unrejected, -> { where(:leave_status.ne => REJECTED )}
  scope :leaves, -> { where(:leave_type.nin => [LEAVE_TYPES[:wfh]]) }

  attr_accessor :sanctioning_manager

  def processed?
    leave_status != PENDING
  end

  def leave_request?
    leave_type == LEAVE_TYPES[:leave]
  end

  def leave?
    leave_request? && self.user.role != ROLE[:consultant]
  end

  def is_leave?
    !leave_type.eql?(LEAVE_TYPES[:wfh])
  end

  def leave_count
    (self.end_at - self.start_at).to_i + 1
  end

  def previous_leave_type?
    self.leave_status == PENDING &&
    self.leave_type_changed? &&
    (self.leave_type_was == LEAVE_TYPES[:leave] || self.leave_type == LEAVE_TYPES[:leave])
  end

  def update_leave_count
    if self.leave_type_was == LEAVE_TYPES[:leave]
      user.employee_detail.add_rejected_leave(self.number_of_days_was)
    else
      user.employee_detail.deduct_available_leaves(self.number_of_days)
    end
  end

  def optional_leave?
    leave_type == LEAVE_TYPES[:optional_holiday]
  end

  def validate_optional_leave
    errors.add(
      :start_at,
      'Optional Holiday can not be applied within One month prior to Optional Holiday date'
    ) if start_at < Date.today + 1.month && start_at.month > 1
    leaves = LeaveApplication.unrejected.where(
      user_id: user_id,
      leave_type: LEAVE_TYPES[:optional_holiday],
      end_at: {
        '$gte': Date.today.beginning_of_year,
        '$lte': Date.today.end_of_year
      }
    )
    leave_count = if self.new_record? || self.leave_type_was != LEAVE_TYPES[:optional_holiday]
                    leaves.count + 1
                  else
                    leaves.count
                  end
    errors.add(:leave_type, 'Cannot apply for more than 2 Optional leaves') if leave_count > 2
  end

  def adjust_leave_count
    overlapping_leave = self.user.leave_applications.where(
      :start_at.lte => self.start_at,
      :end_at.gte => self.start_at,
      leave_type: LEAVE_TYPES[:leave]
    ).first
    return if overlapping_leave.nil?
    employee_detail = self.user.employee_detail
    if pending_or_approved_after_rejecting
      #decrement number of days of overlapping leave by 1
      #increment user's available leaves by 1
      revise_leave_count(overlapping_leave, employee_detail, 'decreament')
    elsif (self.leave_status_was != REJECTED and self.leave_status == REJECTED)
      #increment number of days of overlapping leave by 1
      #decrement user's available leaves by 1
      revise_leave_count(overlapping_leave, employee_detail, 'increament')
    end
  end

  def revise_leave_count(overlapping_leave, employee_detail, operation)
    count = operation.eql?('decreament') ? +1 : -1
    #when operation is 'decreament' then number of days of leave is increamented by 1
    #and user's available leaves is decremented by 1 OR visa versa
    overlapping_leave.update_attributes(number_of_days: overlapping_leave.number_of_days - count)
    #no need to update user's available leaves if overlapping leave is rejected
    employee_detail.update_attributes(
      available_leaves: employee_detail.available_leaves + count
    ) unless overlapping_leave.leave_status == REJECTED
  end

  def pending_or_approved_after_rejecting
    (pending? and self.leave_status_was.nil?) or
    (approved? and self.leave_status_was == REJECTED)
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
    if leave?
      user = self.user
      user.employee_detail.add_rejected_leave(number_of_days)
    end
    UserMailer.delay.reject_leave(self.id)
  end

  def process_accept_application
    UserMailer.delay.accept_leave(self.id)
  end

  def send_leave_notification
    if start_at >= Date.today && is_leave?
      emails = get_team_members
      if emails.present?
        if approved?
          UserMailer.send_accept_leave_notification(id, emails).deliver_now!
        elsif leave_status_changed? && leave_status_was == APPROVED && leave_status == REJECTED
          UserMailer.send_reject_leave_notification(id, emails).deliver_now!
        end
      end
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
        return {type: :error, text: leave_application.errors.full_messages.join(' ')}
      end
    else
      return {type: :error, text: "#{leave_application.leave_type} is already #{leave_status}"}
    end
  end

  def self.get_leaves_for_sending_reminder(date)
    LeaveApplication.leaves.where(
      start_at: date,
      leave_status: APPROVED
    )
  end

  def self.get_optional_holiday_request(date)
    LeaveApplication.where(
      start_at: date,
      leave_status: APPROVED,
      leave_type: LEAVE_TYPES[:optional_holiday]
    )
  end

  def self.get_users_past_leaves(user_id)
    LeaveApplication.leaves.where(
      user_id: user_id,
      start_at: Date.today - 6.month...Date.today,
      leave_status: APPROVED
    ).order_by(:start_at.desc)
  end

  def self.get_users_upcoming_leaves(user_id)
    LeaveApplication.leaves.where(
      user_id: user_id,
      :start_at.gt => Date.today,
      :leave_status.ne => REJECTED
    ).order_by(:start_at.asc)
  end

  def self.pending_leaves_reminder(country)
    count = 0
    date  = Date.today
    while count < 2
      date += 1
      HolidayList.is_holiday?(date, country) ? next : count += 1
      #checking count for 2 days - sending mail only for 1 and 2 day remaining leaves.
      leave_applications = LeaveApplication.where(
        start_at: date,
        leave_status: PENDING,
      )
      next if leave_applications.empty?
      leave_applications.each do |leave_application|
        managers = leave_application.user.get_managers_emails
        UserMailer.pending_leave_reminder(leave_application.user, managers, leave_application).deliver_now
      end
    end
  end

  private

  def deduct_available_leave_send_mail
    # Since leave has been deducted on creation, don't deduct leaves
    # if changed from PENDING to APPROVED
    # Deduct on creation and changed from 'Rejected' to 'Approved'
    if pending_or_approved_after_rejecting
      user = self.user
      user.employee_detail.deduct_available_leaves(number_of_days) if leave?
      user.sent_mail_for_approval(self.id) unless self.leave_status_was == REJECTED
    end
  end

  def update_available_leave_send_mail
    user = self.user
    if !leave_type_changed? && leave?
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
      leave_applications = LeaveApplication.where(
        :start_at.gte => self.start_at.beginning_of_year,
        :leave_status.ne => REJECTED,
        user_id: self.user
      ).ne(id: self.id)

      leave_applications.each do |leave|
        if self.start_at.between?(leave.start_at, leave.end_at) or
           self.end_at.between?(leave.start_at, leave.end_at)
          unless self.is_leave? && leave.leave_type == LEAVE_TYPES[:wfh]
            errors.add(:base, "Already applied for #{leave.leave_type} on same date") and return
          end
        end
      end
    end
  end
end
