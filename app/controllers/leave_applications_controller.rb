class LeaveApplicationsController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource except: [:create, :view_leave_status, :process_leave]
  before_action :authorization_for_admin, only: [:process_leave]

  def new
    @leave_application = LeaveApplication.new(user_id: current_user.id)
    @available_leaves = current_user.employee_detail.try(:available_leaves)
  end

  def index
    @users = User.employees.not_in(role: ['Admin'])
  end

  def create
    @leave_application = LeaveApplication.new(strong_params)
    if @leave_application.save
      flash[:success] = 'Your request has been submitted successfully. Please wait for the approval.'
    else
      @available_leaves = current_user.employee_detail.try(:available_leaves)
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'new' and return
    end
    #redirect_to public_profile_user_path(current_user) and return
    redirect_to view_leaves_path(current_user) and return
  end

  def edit
    @available_leaves = @leave_application.user.employee_detail.available_leaves
  end

  def update
    if @leave_application.update_attributes(strong_params)
      flash[:success] = 'Your request has been updated successfully. Please wait for the approval.'
    else
      @available_leaves = current_user.employee_detail.available_leaves
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'edit' and return
    end
    redirect_to ((can? :manage, LeaveApplication) ? leave_applications_path : view_leaves_path) and return
  end

  def view_leave_status
    @available_leaves = current_user.employee_detail.try(:available_leaves)
    if MANAGEMENT.include? current_user.role
      @pending_leaves = LeaveApplication.where(:user_id.in => user_ids)
        .any_of(search_conditions)
        .pending
        .order_by(:start_at.desc).includes(:user).to_a
      @processed_leaves = LeaveApplication.where(:user_id.in => user_ids)
        .any_of(search_conditions)
        .processed
        .order_by(:start_at.desc).includes(:user).to_a
    else
      @pending_leaves = current_user.leave_applications
        .pending
        .any_of(search_conditions)
        .order_by(:start_at.desc).includes(:user).to_a
      @processed_leaves = current_user.leave_applications
        .processed
        .any_of(search_conditions)
        .order_by(:start_at.desc).includes(:user).to_a
    end
  end

  def strong_params
    safe_params = [
                   :user_id, :start_at, :leave_type,
                   :end_at, :contact_number, :number_of_days,
                   :reason, :reject_reason, :leave_status
                  ]
    params.require(:leave_application).permit(*safe_params)
  end

=begin Commented on 26th may 2015. Added common method process_leave
  def cancel_leave
    reject_reason = params[:reject_reason] || ''
    process_leave(params[:id], 'Rejected', :process_reject_application, reject_reason)
  end

  def approve_leave
    process_leave(params[:id], 'Approved', :process_accept_application)
  end
=end

  def process_leave
    @leave_application = LeaveApplication.find(params[:id])
    if params[:leave_action].present?
      @leave_action = params[:leave_action]
      if params[:leave_action] == 'approve'
        @status = APPROVED
        call_function = :process_accept_application
      else
        @status = REJECTED
        call_function = :process_reject_application
      end
      @message = LeaveApplication.process_leave(params[:id], @status, call_function, params[:reject_reason], current_user.id)
    else
      @leave_application.update_attributes({reject_reason: params[:reject_reason]})
      @message = {:type=>:success, :text=>"Comment Inserted successfully"}
    end

    @pending_leaves = LeaveApplication.order_by(:start_at.desc).pending


    respond_to do|format|
      format.js{}
      format.html{ redirect_to view_leaves_path}
    end
  end

  private

  def authorization_for_admin
    if !(current_user.is_admin? || current_user.is_manager?)
      flash[:error] = 'Unauthorize access'
      redirect_to root_path
    else
      return true
    end
  end

  def search_conditions
    today = Date.today
    beginning_of_year = today.beginning_of_year.strftime("%d-%m-%Y")
    end_of_year = today.end_of_year.strftime("%d-%m-%Y")
    if params[:from].present?
      to = params[:to].empty? ? today.strftime("%d-%m-%Y") : params[:to]
      start_at =  { start_at: params[:from].to_date..to.to_date }
      end_at = { end_at: params[:from].to_date..to.to_date }
      [start_at, end_at]
    else
      start_at =  { start_at: beginning_of_year..end_of_year }
      end_at = { end_at: beginning_of_year..end_of_year }
      [start_at, end_at]
    end
  end

  def user_ids
    active_or_all_flag = params[:active_or_all_flag]
    active_or_all_flag ||= "active" # show active users by default
    if params[:project_id].present? and active_or_all_flag == "active"
      UserProject.where(project_id: params[:project_id]).where(:end_date => nil).pluck(:user_id)
    elsif params[:project_id].present? and active_or_all_flag == "all"
      UserProject.where(project_id: params[:project_id]).pluck(:user_id)
    elsif params[:user_id].present?
      [ params[:user_id] ]
    else
      User.approved.pluck(:id)
    end
  end

  # def user_ids
  #   if params[:name].present?
  #     first_name, last_name = params[:name].split
  #     last_name = first_name if last_name.nil?
  #     User.or({ "public_profile.first_name": /#{first_name}/i}, { "public_profile.last_name": /#{last_name}/i}).pluck(:id)
  #   else
  #     User.pluck(:id)
  #   end
  # end
end
