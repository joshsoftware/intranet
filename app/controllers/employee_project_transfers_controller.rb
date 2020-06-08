class EmployeeProjectTransfersController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource except: [:create]
  before_action :load_users, only: [:new, :edit, :update, :create]
  before_action :load_projects, only: [:new, :edit, :update, :create]

  def index
    @pending_transfers = EmployeeProjectTransfer.pending
    @processed_transfers = EmployeeProjectTransfer.processed
  end

  def new
    @employee_project_transfer = EmployeeProjectTransfer.new(requested_by: current_user.id, requested_date: Date.today)
  end

  def create
    @employee_project_transfer = EmployeeProjectTransfer.new(employee_project_transfer_params)
    if @employee_project_transfer.save
      flash[:success] = "Employee Project Transfer request created Succesfully"
      redirect_to employee_project_transfers_path
    else
      render action: 'new'
    end
  end

  def edit
    @employee_project_transfer = EmployeeProjectTransfer.find(params[:id])
  end

  def update
    @employee_project_transfer = EmployeeProjectTransfer.find(params[:id])
    if @employee_project_transfer.update_attributes(employee_project_transfer_params)
      flash[:success] = "Employee Project Transfer request updated Succesfully"
      redirect_to employee_project_transfers_path
    else
      render action: 'edit'
    end
  end

  def process_request
    @employee_project_transfer = EmployeeProjectTransfer.find(params[:id])
    if params[:perform_action].present?
      if params[:perform_action] == 'approve'
        @message = @employee_project_transfer.process_request(APPROVED)
        @status = APPROVED
      else
        @message = @employee_project_transfer.process_request(REJECTED)
        @status = REJECTED
      end
    else
      @message = {type: :error, text: "Employee Project Transfer request cannot be processed"}
    end
    respond_to do |format|
      format.js {}
      format.html { redirect_to employee_project_transfers_path }
    end
  end

  private

  def employee_project_transfer_params
    params.require(:employee_project_transfer).permit(:requested_date, :request_for, :requested_by,
      :start_date, :end_date, :from_project, :request_reason, :to_project, :allocation)
  end

  def load_users
    @users = User.project_engineers
  end

  def load_projects
    @projects = Project.all
  end
end
