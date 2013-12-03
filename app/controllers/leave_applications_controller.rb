class LeaveApplicationsController < ApplicationController
   
  load_and_authorize_resource except: [:create]
  before_action :authenticate_user!
  before_action :authorization_for_admin, only: [:approve_leave, :cancel_leave]   
 
  def new
    @leave_application = LeaveApplication.new(user_id: current_user.id)
    @leave_types = LeaveType.all.to_a
    @leave_detail = current_user.leave_details.where(year: Date.today.year).first 
  end
  
  def index
    @users = User.employees.not_in(role: ["Admin", "SuperAdmin"])
  end  
  
  def create
    @leave_application = LeaveApplication.new(strong_params)
    if @leave_application.save
      flash[:error] = "Leave Applied Successfully. !Wait till approved"
      current_user.sent_mail_for_approval(from_date: @leave_application.start_at, to_date: @leave_application.end_at) 
    else
      @leave_types = LeaveType.all.to_a 
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'new' and return
    end
    redirect_to public_profile_user_path(current_user) and return 
  end 
  
  def view_leave_status
    @pending_leave = LeaveApplication.order_by(:created_at.desc).where(leave_status: 'Pending')
    @approved_leave = LeaveApplication.where(:leave_status.ne => 'Pending') 
  end

  def strong_params
    safe_params = [
                   :user_id, :leave_type_id, :start_at, 
                   :end_at, :contact_number, :number_of_days,
                   :reason, :reject_reason, :leave_status
                  ]
    params.require(:leave_application).permit(*safe_params) 
  end

  def cancel_leave
    process_leave(params[:id], 'Rejected', :process_reject_application)
  end

  def approve_leave
    process_leave(params[:id], 'Approved', :process_accept_application)
  end 

  private
    def process_leave(id, leave_status, call_function)
      message = LeaveApplication.process_leave(id, leave_status, call_function)
      
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
