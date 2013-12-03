class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, only: [:edit, :update, :show, :public_profile, :private_profile]
  before_action :load_profiles, only: [:public_profile, :private_profile, :update, :edit]
  before_action :build_addresses, only: [:public_profile, :private_profile, :edit]
  before_action :authorize, only: [:public_profile, :edit]
  before_action :authorize_document_download, only: :download_document
  after_action :notify_document_download, only: :download_document

  def index
    @users = User.employees
  end

  def show
    @projects = @user.projects
  end

  def update
    @user.attributes =  user_params
    if @user.save
      flash.notice = 'Profile updated Succesfully'
      #UserMailer.delay.verification(@user.id)
    else
      flash[:error] = "Error #{@user.errors.full_messages.join(' ')}"
    end
    redirect_to public_profile_user_path(@user)
  end

  def public_profile
    profile = params.has_key?("private_profile") ? "private_profile" : "public_profile"
    update_profile(profile)
    load_emails_and_projects
    @user.attachments.first || @user.attachments.build  
  end

  def private_profile
    profile = params.has_key?("private_profile") ? "private_profile" : "public_profile"
    update_profile(profile)
  end
  
  def update_profile(profile)
    user_profile = (profile == "private_profile") ? @private_profile : @public_profile
    if request.put?
      #Need to change these permit only permit attributes which should be updated by user
      #In our application there are some attributes like joining date which will be only 
      #updated by hr of company
      if user_profile.update_attributes(params.require(profile).permit!)
        flash.notice = 'Profile Updated Succesfully'
        #UserMailer.delay.verification(@user.id)
        redirect_to public_profile_user_path(@user)
      else
        render "public_profile"
      end
    end
  end

  def invite_user
    if request.get?
      @user = User.new 
    else
      @user = User.new(params[:user].permit(:email, :role))
      @user.password = Devise.friendly_token[0,20]
      if @user.save
        flash.notice = 'Invitation sent Succesfully'
        UserMailer.delay.invitation(current_user.id, @user.id)
        redirect_to invite_user_path
      else
        render 'invite_user'
      end
    end
  end

  def download_document
    document_type = MIME::Types.type_for(@document.url).first.content_type
    send_file @document.path, filename: @document.model.name, type: "#{document_type}"
  end

  private
  def load_user
    @user = User.find(params[:id])
  end
  
  def user_params
    safe_params = [] 
    if params[:user][:employee_detail_attributes].present?
      safe_params = [ employee_detail_attributes: [:id, :employee_id, :date_of_relieving,:notification_emails => [] ], :project_ids => [] ]
    elsif params[:user][:attachments_attributes].present?
      safe_params = [attachments_attributes: [:id, :name, :document, :_destroy]] 
    else
      safe_params = [:status, :role]
    end
    params.require(:user).permit(*safe_params)
  end

  def load_profiles
    @public_profile = @user.public_profile || @user.build_public_profile
    @private_profile = @user.private_profile || @user.build_private_profile
    @user.employee_detail || @user.build_employee_detail
  end

  def build_addresses
    if request.get?
      ADDRESSES.each{|a| @user.private_profile.addresses.build({:type_of_address => a})} if @user.private_profile.addresses.empty?
      # need atleast two contact persons details
      2.times {@user.private_profile.contact_persons.build} if @user.private_profile.contact_persons.empty?
    end
  end

  def load_emails_and_projects
    @emails = User.all.collect(&:email)
    @projects = Project.all.collect { |p| [p.name, p.id] }
    notification_emails = @user.employee_detail.try(:notification_emails) 
    @notify_users = User.where(:email.in => notification_emails || []) 
  end

  def authorize
    message = "You are not authorize to perform this action"
    (current_user.can_edit_user?(@user)) || (flash[:error] = message; redirect_to root_url)
  end

  def authorize_document_download
    @attachment = Attachment.where(id: params[:id]).first
    @document = @attachment.document
    message = "You are not authorize to perform this action"
    (current_user.can_download_document?(@user, @attachment)) || (flash[:error] = message; redirect_to root_url)
  end

  def notify_document_download
    UserMailer.delay.download_notification(current_user.id, @attachment.name)
  end
end
