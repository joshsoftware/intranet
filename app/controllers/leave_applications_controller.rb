class LeaveApplicationsController < ApplicationController
   
  before_action :authenticate_user!
  load_and_authorize_resource except: [:create, :view_leave_status, :approve_leave, :cancel_leave]
  before_action :authorization_for_admin, only: [:approve_leave, :cancel_leave]   
 
  def new
    @leave_application = LeaveApplication.new(user_id: current_user.id)
    @available_leaves = current_user.employee_detail.try(:available_leaves)
  end
  
  def index
    @users = User.employees.not_in(role: ["Admin", "SuperAdmin"])
  end  
  
  def create
    @leave_application = LeaveApplication.new(strong_params)
    if @leave_application.save
      flash[:error] = "Leave Applied Successfully. !Wait till approved"
    else
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'new' and return
    end
    redirect_to public_profile_user_path(current_user) and return 
  end 

  def edit
    @available_leaves = @leave_application.user.employee_detail.available_leaves
  end

  def update
    if @leave_application.update_attributes(strong_params)
      flash[:error] = "Leave Has Been Updated Successfully. !Wait till approved"
    else
      @available_leaves = current_user.employee_detail.available_leaves
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'edit' and return
    end 
    redirect_to ((can? :manage, LeaveApplication) ? leave_applications_path : view_leaves_path) and return 
  end

  def view_leave_status
    if ["Admin", "HR", "Manager"].include? current_user.role
      @pending_leave = LeaveApplication.order_by(:created_at.desc).pending
      @approved_leave = LeaveApplication.order_by(:created_at.desc).processed 
    else
      @pending_leave = current_user.leave_applications.order_by(:created_at.desc).pending
      @approved_leave = current_user.leave_applications.order_by(:created_at.desc).processed
    end
  end

  def strong_params
    safe_params = [
                   :user_id, :start_at, 
                   :end_at, :contact_number, :number_of_days,
                   :reason, :reject_reason, :leave_status
                  ]
    params.require(:leave_application).permit(*safe_params) 
  end

  def cancel_leave
    reject_reason = params[:reject_reason] || ''
    process_leave(params[:id], 'Rejected', :process_reject_application, reject_reason)
  end

  def approve_leave
    process_leave(params[:id], 'Approved', :process_accept_application)
  end 

  private

    def process_leave(id, leave_status, call_function, reject_reason = '')
      message = LeaveApplication.process_leave(id, leave_status, call_function, reject_reason)
      
      respond_to do|format|
        format.html do
          flash[message[:type]] = message[:text]
          redirect_to root_path 
        end
        format.js{ render :nothing => true}
      end
    end
    
    def authorization_for_admin
      if !current_user.role?("Admin")
        flash[:error] = 'Unauthorize access'
        redirect_to root_path
      else
        return true
      end
    end 
end
