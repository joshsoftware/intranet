class UserMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com' 
  
  def invitation(sender_id, receiver_id)
    @sender = User.where(id: sender_id).first
    @receiver = User.where(id: receiver_id).first
    mail(from: @sender.email, to: @receiver.email, subject: "Invitation to join Josh Intranet")
  end

  def verification(updated_user_id)
    admin_emails = User.where(role: 'Admin').all.map(&:email)
    @updated_user = User.where(id: updated_user_id).first
    hr = User.where(role: 'HR').first
    receiver_emails = [admin_emails, hr.email].flatten.join(',')
    mail(to: receiver_emails , subject: "#{@updated_user.public_profile.name} Profile has been updated")
  end
  
  def leave_application(sender_email, receivers, leave_application_id)
    @user = User.find_by(email: sender_email)
    @receivers = receivers
    @leave_application = LeaveApplication.where(id: leave_application_id).first
    mail(from: @user.email, to: receivers, subject: "#{@user.name} has applied for leave")
  end

  def reject_leave(leave_application_id)
    get_leave(leave_application_id)
    mail(to: @user.email, subject: "Leave Request got rejected")
  end

  def accept_leave(leave_application_id)
    get_leave(leave_application_id)
    mail(to: @user.email, subject: "Congrats! Leave Request got accepted")
  end

  def download_notification(downloader_id, document_name)
    @downloader = User.find(downloader_id)
    @document_name = document_name
    hr = User.where(role: 'HR').first
    mail(to: hr.email, subject: "Intranet: #{@downloader.name} has downloaded #{document_name}")
  end
  
  def birthday_wish(user_ids)
    users = User.find(user_ids)
    @names = users.map(&:name).join(', ')  
    mail(to: "all@joshsoftware.com", subject: "Happy Birthday #{@names}") 
  end

  def year_of_completion_wish(user_ids)
    users = User.find(user_ids)
    get_user_years(users)
    mail(to: "all@joshsoftware.com", subject: "Congratulations #{@user_hash.collect{|k, v| v }.flatten.join(", ")}") 
  end
  private
    
    def get_user_years(users)
      current_year = Date.today.year
      @user_hash = {}
      users.each do |user|
        completion_year = current_year - user.private_profile.date_of_joining.year
        if completion_year > 0
          @user_hash[completion_year].nil? ? @user_hash[completion_year] = [user.name] : @user_hash[completion_year] << user.name 
        end
      end
    end

    def get_leave(id)
      @leave_application = LeaveApplication.where(id: id).first
      @user = @leave_application.user
    end
end
