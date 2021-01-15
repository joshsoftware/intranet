desc 'Notify team members about the leave status'
task approved_leave_notification: :environment do
  leaves = LeaveApplication.leaves.where(
    leave_status: APPROVED,
    start_at: Date.tomorrow
  ).reject { |leave| is_leave_overlapping?(leave) }

  leaves.each do |leave|
    emails = leave.get_team_members
    UserMailer.delay.send_approved_leave_notification(leave.id, emails) if emails.present?
  end
end

def is_leave_overlapping?(leave)
  leave.optional_leave? &&
  LeaveApplication.nin(id: leave).where(
    user: leave.user,
    :end_at.gte => Date.tomorrow,
    :start_at.lte => Date.tomorrow,
    leave_status: APPROVED,
    :leave_type.in => [LeaveApplication::LEAVE, LeaveApplication::SPL]
  ).exists?
end