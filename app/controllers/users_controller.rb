class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, only: [:edit, :update, :show, :public_profile, :private_profile, :get_feed]
  before_action :load_profiles, only: [:public_profile, :private_profile, :update, :edit]
  before_action :build_addresses, only: [:public_profile, :private_profile, :edit]
  before_action :authorize, only: [:public_profile, :edit]
  before_action :authorize_document_download, only: :download_document
  after_action :notify_document_download, only: :download_document

  def index
    if params[:query]
      @users = User.any_of(:email=>Regexp.new(".*" +params[:query] +".*")).to_a
    else
      @users = User.all
    end
    @users = @users.sort{|u1, u2| u1.name.to_s <=> u2.name.to_s} 
    respond_to do |format|  
      format.html # index.html.erb
      format.json { render json: @users }
    end
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
      #
      #update_attribute was getting called on embedded_document so slug which is defined in parent was not getting updated so 
      #update_attributes is caaled on user insted of public_profile/private_profile
      if @user.update_attributes(profile => params.require(profile).permit!)
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

  def update_available_leave
    user = User.find(params[:id])
    user.employee_detail.available_leaves = params[:value]
    user.save
    render nothing: true
  end

  def get_feed
    @feed_type = params["feed_type"]
    case @feed_type
      when "github"
        @github_entries = get_github_feed
      when "bonusly"
        @bonusly_updates = get_bonusly_messages
        if @bonusly_updates.eql?('Not found')
          @not_found = true
        else
          @bonus_received = @bonusly_updates.select{|message| message["receiver"]["email"] == @user.email}
          @bonus_given = @bonusly_updates.select{|message| message["giver"]["email"] == @user.email}
        end
      when "blog"
        @blog_entries   = get_blog_feed
    end
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
    @emails = User.approved.collect(&:email)
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

  def get_bonusly_messages
    bonusly = Api::Bonusly.new(BONUSLY_TOKEN)
    bonusly.bonusly_messages(start_time: Date.today.strftime('%B+1st'), 
                             end_time:   Date.today.end_of_month.strftime('%B+%dst'),
                             user_email: @user.email)
  end

  def get_github_feed
    handle = @user.public_profile.github_handle
    return nil if handle.blank?
    
    github_feed = Feedjira::Feed.fetch_and_parse "https://github.com/#{handle}.atom"
    
    return nil if github_feed.eql?(404) or github_feed.try(:enries).try(:blank?)
    if github_feed != 200
      github_commits = []
      github_feed.entries.each do |entry|
        github_commits.push entry if entry.title.include?("pushed to") || entry.title.include?("wiki")
        break if github_commits.length == 10
      end
      github_commits
    else
      []
    end
  end

  def get_blog_feed
    blog_url = @user.public_profile.blog_url
    return if blog_url.blank?
    blog_feed = Feedjira::Feed.fetch_and_parse "#{blog_url}/feed"
    return nil if blog_feed.try(:entries).try(:blank?)
    if blog_feed != 0
      blog_feed.entries[0..9]
    else
      []
    end
  end

end
