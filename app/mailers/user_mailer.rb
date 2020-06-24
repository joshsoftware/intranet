class UserMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'

  def invitation(sender_id, receiver_id)
    @sender = User.where(id: sender_id).first
    @receiver = User.where(id: receiver_id).first
    mail(from: @sender.email, to: @receiver.email, subject: "Invitation to join Josh Intranet")
  end

  def verification(updated_user_id)
    admin_emails = User.approved.where(role: 'Admin').all.map(&:email)
    @updated_user = User.where(id: updated_user_id).first
    hr = User.approved.where(role: 'HR').first
    receiver_emails = [admin_emails, hr.email].flatten.join(',')
    mail(to: receiver_emails , subject: "#{@updated_user.public_profile.name} Profile has been updated")
  end

  def leave_application(sender_email, receivers, leave_application_id)
    @user = User.find_by(email: sender_email)
    @receivers = receivers
    @older_leaves = LeaveApplication.get_users_past_leaves(@user.id)
    @next_planned_leaves = LeaveApplication.get_users_upcoming_leaves(@user.id).where(
      :id.ne => leave_application_id
    )
    @leave_application = LeaveApplication.where(id: leave_application_id).first
    mail(from: @user.email, to: receivers, subject: "#{@user.name} has applied for #{@leave_application.leave_type}")
  end

  def reject_leave(leave_application_id)
    get_leave(leave_application_id)
    mail(to: @notification_emails, subject: "#{@leave_application.leave_type} Request got rejected")
  end

  def accept_leave(leave_application_id)
    get_leave(leave_application_id)
    mail(to: @notification_emails, subject: "Congrats! #{@leave_application.leave_type} Request got accepted")
  end

  def download_notification(downloader_id, document_name)
    @downloader = User.find(downloader_id)
    @document_name = document_name
    hr = User.approved.where(role: 'HR').try(:first).try(:email) || 'hr@joshsoftware.com'
    mail(to: hr, subject: "Intranet: #{@downloader.name} has downloaded #{document_name}")
  end

  def birthday_wish(user_id)
    @birthday_user = User.find(user_id)
    url = @birthday_user.public_profile.image.medium.path || "#{Rails.root}/app/assets/images/default_photo.gif"
    attachments.inline['user.jpg'] = File.read(url)
    mail(to: "all@joshsoftware.com", subject: "Happy Birthday #{@birthday_user.name}")
  end

  def year_of_completion_wish(user_hash)
    @user_hash = user_hash
    mail(to: "all@joshsoftware.com", subject: "Congratulations #{@user_hash.collect{|k, v| v }.flatten.join(", ")}")
  end

  def leaves_reminder(leaves)
    hr_emails = User.approved.where(role: 'HR').collect(&:email)
    admin_emails = User.approved.where(role: 'Admin').all.map(&:email)
    @receiver_emails = [admin_emails, hr_emails].flatten.join(',')
    leaves.map do |leave|
      leave.sanctioning_manager = User.where(id: leave.processed_by).first.try(:name)
    end
    @leaves = leaves
    mail(to: @receiver_emails, subject: "Employees on leave tomorrow.") if leaves.present?
  end

  def new_blog_notification(params)
    body = <<-body
      #{params[:post_url]}
    body

    mail(subject: "New blog '#{params[:post_title]}' has been published", body: body,
         to: 'all@joshsoftware.com')
  end

  def new_policy_notification(policy_id)
    @policy = Policy.find(policy_id)
    mail(subject: "New policy has been added",to: 'all@joshsoftware.com' )
  end

  def database_backup(path, file_name)
    attachments[file_name] = File.read("#{path}/#{file_name}")
    mail(subject: 'Josh Intranet: Daily database backup', to: ADMIN_EMAILS)
  end

  def profile_updated(changes, user_name)
    changes.delete('updated_at')
    @changes = changes.to_a
    hr = User.approved.where(role: 'HR').try(:first).try(:email) || 'hr@joshsoftware.com'
    @user_name = user_name
    mail(subject: 'Profile updated', to: hr)
  end

  def pending_leave_reminder(user, managers, leave)
    @user     = user
    hr_emails = User.get_hr_emails
    @leave    = leave
    mail(
      subject: 'Action Required on Pending Leave Requests',
      to: managers,
      cc: hr_emails
    )
  end

  def new_entry_passes(entry_passes_ids)
    @entry_passes = EntryPass.where(:id.in => entry_passes_ids).sort_by(&:date)
    @user = @entry_passes.first.user
    mail(
      subject: "Office Entry Pass created by #{@user.name}",
      to: [OFFICE_ENTRY_PASS_MAIL_RECEPIENT, @user.email].flatten
    )
  end

  def delete_office_pass(date, user_id, deleted_by)
    @date = date
    @user = User.find(user_id)
    @deleted_by = User.find(deleted_by)
    mail(
      subject: 'Your office entry pass is deleted',
      to: @user.email,
      cc: User.get_hr_emails
    )
  end

  def notify_probation(users, date)
    @users    = users
    @date     = date
    hr_emails = User.get_hr_emails
    mail(
      subject: 'Action Required: Probation period of employees ending soon',
      to: hr_emails
    )
  end

  private

  def get_leave(id)
    @leave_application = LeaveApplication.where(id: id).first
    @user = @leave_application.user
    @processed_by = User.find(@leave_application.processed_by)
    @notification_emails = [@user.email, @user.notification_emails].flatten.compact.uniq.join(', ')
  end
end
