desc 'Notify team members about the leave status'
task :approved_leave_notification => :environment do
  unless HolidayList.is_holiday?(Date.today)
    leaves = LeaveApplication.where(leave_type: 'LEAVE',
                                    leave_status: 'Approved',
                                    start_at: Date.tomorrow)
    leaves.each do |leave|
      emails = leave.get_team_members
      UserMailer.delay.send_approved_leave_notification(leave.id, emails)
    end
  end
end
