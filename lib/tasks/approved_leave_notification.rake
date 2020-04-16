desc 'Notify team members about the leave status'
task approved_leave_notification: :environment do
  leave_types = [
    LeaveApplication::LEAVE,
    LeaveApplication::OPTIONAL
  ]
  leaves = LeaveApplication.where(
    leave_status: APPROVED,
    start_at: Date.tomorrow,
    :leave_type.in => leave_types
  )
  leaves.each do |leave|
    emails = leave.get_team_members
    UserMailer.delay.send_approved_leave_notification(leave.id, emails) if emails.present?
  end
end
