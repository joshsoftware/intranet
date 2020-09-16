class TimeSheetsController < ApplicationController
  before_action :authenticate_user!
  skip_before_filter :verify_authenticity_token
  load_and_authorize_resource only: [:index, :users_timesheet, :edit_timesheet, :update_timesheet,
                                     :new, :projects_report, :add_time_sheet, :import]
  load_and_authorize_resource only: :individual_project_report, class: Project
  before_action :user_exists?, only: [:create, :daily_status]

  def new
    @from_date = params[:from_date] || Date.today.beginning_of_month.to_s
    @to_date = params[:to_date] || Date.today.to_s
    @user = User.find_by(id: params[:user_id]) if params[:user_id].present?
    @time_sheets = @user.time_sheets.build
  end

  def create
    return_value, time_sheets_data = @time_sheet.parse_timesheet_data(params) unless params['user_id'].nil?
    if return_value == true
      create_time_sheet(time_sheets_data, params)
    else
      render json: { text: '' }, status: :bad_request
    end
  end

  def index
    @from_date = params[:from_date] || Date.today.beginning_of_month.to_s
    @to_date = params[:to_date] || Date.today.to_s
    @user = current_user
    timesheets = TimeSheet.load_timesheet(@time_sheets.pluck(:id), @from_date.to_date, @to_date.to_date) if TimeSheet.from_date_less_than_to_date?(@from_date, @to_date)
    @timesheet_report, @users_without_timesheet = TimeSheet.generate_employee_timesheet_report(timesheets, @from_date.to_date, @to_date.to_date, @user) if timesheets.present?
  end

  def users_timesheet
    unless current_ability.can? :users_timesheet, TimeSheet.where(user_id: params[:user_id]).first
      flash[:error] = "Invalid access"
      redirect_to time_sheets_path and return
    end
    @from_date = params[:from_date] || Date.today.beginning_of_month.to_s
    @to_date = params[:to_date] || Date.today.to_s
    @user = User.find(params[:user_id])
    @individual_timesheet_report, @total_work_and_leaves = {}, {}
    if TimeSheet.from_date_less_than_to_date?(@from_date, @to_date)
      @individual_timesheet_report, @total_work_and_leaves = TimeSheet.generate_individual_timesheet_report(@user, params)
    else
      flash[:error] = 'Please select appropriate date'
    end
  end

  def edit_timesheet
    unless current_ability.can? :edit_timesheet, TimeSheet.where(user_id: params[:user_id]).first
      flash[:error] = "Invalid access"
      redirect_to users_time_sheets_path and return
    end
    @from_date = params[:from_date]
    @to_date = params[:to_date]
    @user = User.find_by(id: params[:user_id])
    @time_sheets = @user.time_sheets.where(date: params[:time_sheet_date].to_date)
    @time_sheet_date = params[:time_sheet_date]
  end

  def update_timesheet
    unless current_ability.can? :update_timesheet, TimeSheet.where(user_id: params[:user_id]).first
      flash[:error] = "Invalid access"
      redirect_to edit_time_sheets_path and return
    end
    @from_date = Date.today.beginning_of_month.to_s
    @to_date = Date.today.to_s
    @user = User.find_by(id: params['user_id'])
    @time_sheet_date = params[:time_sheet_date]
    @time_sheets = @user.time_sheets.where(date: params[:time_sheet_date].to_date)
    if(current_user.is_employee_or_intern? && @time_sheets.last.valid_date_for_update?) ||
      current_user.is_admin_or_hr? || current_user.is_manager?
      return_value, @time_sheets = TimeSheet.update_time_sheet(@time_sheets, current_user, timesheet_params)
      unless return_value.include?(false)
        flash[:notice] = 'Timesheet Updated Successfully'
        redirect_to users_time_sheets_path(@user.id, from_date: @from_date, to_date: @to_date)
      else
        render 'edit_timesheet'
      end
    else
      text = "Not allowed to edit timesheet for this date. You can edit timesheet for past #{TimeSheet::DAYS_FOR_UPDATE} days."
      flash[:error] = text
      render 'edit_timesheet'
    end
  end

  def add_time_sheet
    if params['user'].present?
      @from_date = params['user']['from_date']
      @to_date = params['user']['to_date']
      @user = User.find_by(id: params['user']['user_id'])
    
      data_params = timesheet_params['time_sheets_attributes'].reject{|key, data| data["_destroy"] == "1"}
      data_params = {"time_sheets_attributes"=>data_params}
      return_values, @time_sheets = TimeSheet.create_time_sheet(@user.id, current_user, data_params)
      unless return_values.include?(false)
        flash[:notice] = 'Timesheet created successfully'
        redirect_to users_time_sheets_path(user_id: @user.id, from_date: @from_date, to_date: @to_date)
      else
        if return_values.include?(true)
          flash[:notice] = "#{return_values.count(true)} #{'timesheet'.pluralize(return_values.count(true))} created successfully"
        end
        render 'new'
      end
    elsif request.env['REQUEST_METHOD'] == 'GET'
      redirect_to time_sheets_path
    end
  end

  def create_time_sheet(time_sheets_data, params)
    @time_sheet.attributes = time_sheets_data
    if @time_sheet.save
      render json: { text: "*Timesheet saved successfully!*" }, status: :created
    else
      error_message =
        if @time_sheet.errors[:date].present?
          error =  @time_sheet.errors[:date] if @time_sheet.errors[:date].present?
          TimeSheet.create_error_message_for_slack(error)
        elsif @time_sheet.errors[:from_time].present? || @time_sheet.errors[:from_time].present?
          error =  @time_sheet.errors[:from_time] if @time_sheet.errors[:from_time].present?
          error = @time_sheet.errors[:to_time] if @time_sheet.errors[:to_time].present?
          TimeSheet.create_error_message_for_slack(error)
        else
          TimeSheet.create_error_message_for_slack(@time_sheet.errors.full_messages)
        end
      SlackApiService.new.post_message_to_slack(params['channel_id'], error_message.join(' '))
      render json: { text: 'Fail' }, status: :unprocessable_entity
    end
  end

  def daily_status
    @time_sheet = TimeSheet.new
    time_sheet_log = TimeSheet.parse_daily_status_command(params)
    if time_sheet_log
      render json: { text: time_sheet_log }, status: :ok
    else
      render json: { text: 'Fail' }, status: :unprocessable_entity
    end
  end

  def projects_report
    @from_date = params[:from_date] || Date.today.beginning_of_month.to_s
    @to_date = params[:to_date] || Date.today.to_s
    @projects_report = TimeSheet.load_projects_report(@from_date.to_date, @to_date.to_date) if TimeSheet.from_date_less_than_to_date?(@from_date, @to_date)
    @projects_report_in_json, @project_without_timesheet =
      TimeSheet.create_projects_report_in_json_format(@projects_report, @from_date.to_date, @to_date.to_date)
  end

  def individual_project_report
    @from_date = params[:from_date]
    @to_date = params[:to_date]
    @project = Project.find(params[:id])
    @individual_project_report, @project_report = TimeSheet.generate_individual_project_report(@project, params) if TimeSheet.from_date_less_than_to_date?(@from_date, @to_date)
  end

  def export_project_report
    @from_date = params[:from_date] || Date.today.beginning_of_month.to_s
    @to_date = params[:to_date] || Date.today.to_s
    if params['project_id'].present?
      TimesheetSummaryReportWorker.perform_async(
        params,
        @from_date,
        @to_date,
        current_user.id.to_s
      )
      flash[:success] = "You will receive summary report to your mail shortly."
    end
  end

  def export_resource_report
    ResourceCategorisationWorker.perform_async(current_user.email)
    flash[:success] = 'You will receive resource categorisation report to your mail shortly.'
    redirect_to export_project_report_time_sheets_path
  end

  def import
    if params[:file].present? && params[:file_name]
      ImportTimesheetWorker.perform_async(params[:file].path, params[:file_name], current_user.email)
      flash[:notice] = 'File Uploaded Successfully, you will shortly receive a mail regarding the processing result of the file.'
    else
      flash[:error] = 'Please enter all the required fields.'
    end
    redirect_to time_sheets_path
  end

  private

  def user_exists?
    load_user
    @time_sheet = TimeSheet.new
    @user = TimeSheet.fetch_email_and_associate_to_user(params['user_id']) if @user.blank?
    unless @user
      render json: { text: 'You are not part of organization contact to admin' }, status: :unauthorized
    end
  end

  def load_user
    @user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
  end

  def timesheet_params
    params.require(:user).permit(:time_sheets_attributes => [:project_id, :date, :from_time, :to_time, :description, :id, :_destroy, :user_id, :from_date, :to_date, :duration ])
  end
end
