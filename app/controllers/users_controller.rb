class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, only: [:edit, :update, :show, :public_profile, :private_profile, :get_feed]
  before_action :load_profiles, only: [:public_profile, :private_profile, :update, :edit]
  before_action :build_addresses, only: [:public_profile, :private_profile, :edit]
  before_action :authorize, only: [:public_profile, :edit]
  before_action :authorize_document_download, only: :download_document

  def index
    if current_user.role == ROLE[:consultant]
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to public_profile_user_path(current_user)
    elsif request.format.xlsx? && !MANAGEMENT.include?(current_user.role)
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to root_path
    else
      @users = params[:all].present? ?  User.employees : User.employees.approved
      @usersxls = params[:status] == "all" ? User.nin(status: STATUS[:created]).employees : User.employees.approved
      respond_to do |format|
        format.html # index.html.erb
        format.xlsx
        format.js
        format.json { render json: @users.to_json }
      end
    end
  end

  def show
    @projects = @user.projects.where(is_active: 'true')
    @managed_projects = @user.managed_projects.where(:_id.nin => @projects.pluck(:id), is_active: 'true')
  end

  def update
    return_value_of_add_project = return_value_of_remove_project = true
    @user.attributes = user_params
    return_value_of_add_project, return_value_of_remove_project = @user.add_or_remove_projects(params) if params[:user][:project_ids].present?
    if return_value_of_add_project && return_value_of_remove_project
      if @user.save
        flash.notice = "#{current_tab} updated Successfully"
        redirect_to public_profile_user_path(@user)
      else
        # @current_assets = @user.assets.reject{|asset| asset.recovered}
        @current_assets = @user.assets.where(recovered: false).order_by(:date_of_issue.desc)
        load_emails_and_projects
        flash[:error] = "#{current_tab}: Error #{@user.generate_errors_message}"
        render 'public_profile'
      end
    else
      flash[:error] = 'Error unable to add or remove project'
      redirect_to public_profile_user_path(@user)
    end
  end

  def public_profile
    profile = params.has_key?("private_profile") ? "private_profile" : "public_profile"
    update_profile(profile)
    @user.attachments.first || @user.attachments.build
  end

  def private_profile
    profile = params.has_key?("private_profile") ? "private_profile" : "public_profile"
    update_profile(profile)
  end

  def update_profile(profile)
    load_emails_and_projects
    user_profile = (profile == "private_profile") ? @private_profile : @public_profile
    if request.put?
      #Need to change these permit only permit attributes which should be updated by user
      #In our application there are some attributes like joining date which will be only
      #updated by hr of company
      #
      #update_attribute was getting called on embedded_document so slug which is defined in parent was not getting updated so
      #update_attributes is caaled on user insted of public_profile/private_profile
      if @user.update_attributes(profile => params.require(profile).permit!)
        flash.notice = 'Profile Updated Successfully'
        #UserMailer.delay.verification(@user.id)
        redirect_to public_profile_user_path(@user)
      else
        tab = (profile == "private_profile") ? 'Private Profile' : 'Public Profile'
        flash[:error] = "#{tab}: Error #{@user.generate_errors_message}"
        render "public_profile"
      end
    end
  end

  def invite_user
    if request.get?
      @user = User.new
      @user.employee_detail = EmployeeDetail.new
    else
      @user = User.new(params[:user].permit(:email, :role, employee_detail_attributes: [:location] ))
      @user.password = Devise.friendly_token[0,20]
      if @user.save
        flash.notice = 'Invitation sent Successfully'
        UserMailer.delay.invitation(current_user.id, @user.id)
        redirect_to invite_user_path
      else
        render 'invite_user'
      end
    end
  end

  def download_document
    document_type = MIME::Types.type_for(@document.url).first.content_type
    document_extension = '.' + @document.file.extension.downcase
    send_file(
      @document.path,
      filename: @document.model.name + document_extension,
      type: "#{document_type}"
    )
    notification_not_required = DOCUMENT_MANAGEMENT.include?(current_user.role) ||
                                @attachment.instance_of?(Asset)
    notify_document_download unless notification_not_required
  end

  def update_available_leave
    user = User.find(params[:id])
    user.employee_detail.update_attributes(available_leaves: params[:value])
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

  def resource_list
    @technical_skills = (LANGUAGE + FRAMEWORK + OTHER).sort
    @projects = Project.pluck(:name).sort
    @users = User.employees.approved
  end

  def resource_list_download
    @users = User.employees.approved
    send_data @users.to_csv, filename: "EmployeeList - #{Time.now.strftime("%d%b%y%k%M")}.csv"
  end

  def users_optional_holiday_list
    optional_holiday = current_user.leave_applications.unrejected.where(
      :start_at.gte => Date.current.beginning_of_year,
      leave_type: LEAVE_TYPES[:optional_holiday]
    ).pluck(:start_at)
    render json: {user_optional_holiday: optional_holiday}
  end

  private
  def load_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :status, :role, :visible_on_website, :website_sequence_number, :allow_backdated_timesheet_entry,
      employee_detail_attributes: [:id, :employee_id, :location, :date_of_relieving, :source,
      :reason_of_resignation, :designation, :division, :description, :is_billable,
      :skip_unassigned_project_ts_mail, :designation_track, :joining_bonus_paid,
      :assessment_platform, :assessment_month => [], :notification_emails => [] ],
      attachments_attributes: [:id, :name, :document, :_destroy],
      assets_attributes: [:id, :name, :model, :serial_number, :type, :date_of_issue,
      :date_of_return, :valid_till, :before_image, :after_image, :recovered, :_destroy]
    )
  end

  def load_profiles
    @public_profile = @user.public_profile || @user.build_public_profile
    @private_profile = @user.private_profile || @user.build_private_profile
    @user.employee_detail || @user.build_employee_detail
    assets = @user.assets
    @current_assets = assets.where(recovered: false).order_by(:date_of_issue.desc)
    @previous_assets = assets.where(recovered: true).order_by(:date_of_issue.desc)
  end

  def build_addresses
    if request.get?
      ADDRESSES.each{|a| @user.private_profile.addresses.build({:type_of_address => a})} if @user.private_profile.addresses.empty?
      # need atleast two contact persons details
      2.times {@user.private_profile.contact_persons.build} if @user.private_profile.contact_persons.empty?
    end
  end

  def load_emails_and_projects
    @emails = User.approved.pluck(:email).sort
    @projects = Project.all.collect { |p| [p.name, p.id] }
    notification_emails = @user.employee_detail.try(:notification_emails)
    @notify_users = User.where(:email.in => notification_emails || [])
    @current_user_projects = @user.user_projects.where(active: true).order_by(:end_date.desc)
    @previous_user_projects = @user.user_projects.where(active: false).order_by(:end_date.desc)
  end

  def authorize
    message = "You are not authorize to perform this action"
    (current_user.can_edit_user?(@user)) || (flash[:error] = message; redirect_to root_url)
  end

  # def authorize_document_download is used to authorising and handling failures
  # while downloading user documents or before_image and after_image of assets
  def authorize_document_download
    @attachment = Attachment.where(id: params[:id]).first ||
                  Asset.where(id: params[:id]).first
    @document = @attachment.try(:document) ||
                @attachment.try(:"#{params[:image]}")
    unless @document.present?
      message = 'You are trying to download invalid document'
      flash[:error] = message
      redirect_to public_profile_user_path(@attachment.user)
    end
    message = 'You are not authorize to perform this action'
    (current_user.can_download_document?(@user, @attachment)) ||
    (flash[:error] = message; redirect_to root_url)
  end

  def notify_document_download
    UserMailer.delay.download_notification(
      current_user.id,
      @attachment.name
    )
  end

  def get_bonusly_messages
    bonusly = Api::Bonusly.new(BONUSLY_TOKEN)
    bonusly.bonusly_messages(
      start_time: Date.today.strftime('%B+1st'),
      end_time:   Date.today.end_of_month.strftime('%B+%dst'),
      user_email: @user.email
    )
  end

  def get_github_feed
    handle = @user.public_profile.github_handle
    @github_message = "#{@user.name} has not entered github handle yet!!" if handle.blank?
    return nil if handle.blank?

    xml_feed = Feedjira::Feed.fetch_raw "https://github.com/#{handle}.atom"

    if xml_feed.eql?(404)
      @github_message = "The server has not found anything matching the URI given!!"
      return nil
    end

    github_feed = Feedjira::Feed.parse xml_feed

    return nil if github_feed.try(:entries).try(:blank?)

    if github_feed != 200
      github_commits = []
      github_feed.entries.each do |entry|
        github_commits.push entry if entry.title.include?("pushed to") || entry.title.include?("wiki")
        break if github_commits.length == 10
      end
      github_commits
    else
     @github_message = "No github entries found for #{@user.name}!!"
     nil
    end
  end

  def get_blog_feed
    blog_url = @user.public_profile.blog_url
    @blog_message = "#{@user.name} has not entered blog url yet!!" if blog_url.blank?

    return if blog_url.blank?

    xml_feed = Feedjira::Feed.fetch_raw get_blog_url(blog_url)
    if xml_feed.eql?(0)
      @blog_message = "The server has not found anything matching the URI given!!"
      return nil
    end

    begin
      blog_feed = Feedjira::Feed.parse xml_feed
    rescue
      @blog_message = "Invalid Blog URL!!"
      UserMailer.delay.invalid_blog_url(@user.id) if @user.is_approved?
      return nil
    end

    if blog_feed != 0
      blog_feed.entries[0..9]
    else
      @blog_message = "No blog entries found for #{@user.name}!!"
      nil
    end
  end

  def get_blog_url(url)
    "#{url}/feed"
  end

  def current_tab
    return 'Documents' if params[:user][:attachments_attributes].present?
    return 'Employee details' if params[:user][:employee_detail_attributes].present?
    return 'Assets' if params[:user][:assets_attributes].present?
  end

  def current_tab
    return 'Documents' if params[:user][:attachments_attributes].present?
    return 'Employee details' if params[:user][:employee_detail_attributes].present?
    return 'Assets' if params[:user][:assets_attributes].present?
  end
end
