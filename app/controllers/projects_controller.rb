class ProjectsController < ApplicationController
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!

  before_action :load_project, except: [:index, :new, :create, :remove_team_member, :add_team_member, :generate_code, :export_project_report]
  before_action :load_users, only: [:edit, :update]

  include RestfulAction

  def index
    @projects = params[:all].present? ? @projects.asc(:name) : @projects.all_active
    respond_to do |format|
      format.js
      format.html
      format.csv do
        send_data @projects.to_csv, filename: "ProjectsData - #{Date.today.strftime("%d%b%y")}.csv"
      end
    end
  end

  def export_project_report
    username = current_user.name
    user_email = current_user.email
    flash[:success] = "You will receive project team data report to your mail shortly."
    ProjectMailer.delay.send_project_team_report(username, user_email)
    redirect_to projects_path
  end

  def new
    @company = Company.find(params[:company_id]) if params[:company_id]
    @project = Project.new(company: @company)
    @project.technology_details.build
  end

  def create
    @project = Project.new(safe_params)
    if @project.save
      flash[:success] = "Project created Successfully"
      redirect_to projects_path
    else
      render 'new'
    end
  end

  def update
    update_obj(@project, safe_params, edit_project_path)
  end

  def show
    @managers = @project.managers.approved
    @team_members = @project.users - @managers
  end

  def destroy
    if @project.destroy
     flash[:notice] = "Project deleted Successfully"
    else
     flash[:notice] = "Error in deleting project"
    end
     redirect_to projects_path
  end

  def update_sequence_number
    @project.move(to: params[:position].to_i)
    render nothing: true
  end

  def remove_team_member
    if params[:role] == ROLE[:manager]
      team_member = @project.managers.find(params[:user_id])
      @project.manager_ids.delete(team_member.id)
    else
      team_member = @project.users.find(params[:user_id])
      user_project = UserProject.where(user_id: team_member.id, project_id: @project.id, end_date: nil).first
      user_project.update_attributes(end_date: DateTime.now)
    end
    @project.save
    @users = @project.reload.users
    @managers = @project.reload.managers
  end

  def add_team_member
    @project.add_or_remove_team_member(params)
    @users = @project.reload.users
    @managers = @project.reload.managers
  end

  def generate_code
    code = loop do
      random_code = [*'0'..'9',*'A'..'Z',*'a'..'z'].sample(6).join.upcase
      break random_code unless Project.where(code: random_code).first
    end
    render json: { code: code }
  end

  private
  def safe_params
    params.require(:project).permit(:name, :display_name, :start_date, :end_date, :code_climate_id, :code_climate_snippet,
    :code_climate_coverage_snippet, :is_active, :timesheet_mandatory, :ruby_version, :rails_version, :database, :database_version, :deployment_server,
    :deployment_script, :web_server, :app_server, :payment_gateway, :image_store, :index_server, :background_jobs, :sms_gateway,
    :other_frameworks,:other_details, :image, :url, :description, :case_study,:logo, :visible_on_website, :website_sequence_number,
    :code, :number_of_employees, :invoice_date, :company_id, :billing_frequency, :type_of_project, :is_activity,
    :manager_ids => [], technology_details_attributes: %i[id name version _destroy],
    user_projects_attributes: [:start_date, :end_date, :time_sheet, :billable, :allocation, :active, :id, :_destroy, :user_id],
    repositories_attributes: %i[id name host url code_climate_id maintainability_badge test_coverage_badge visibility _destroy rollbar_access_token])
  end

  def load_project
    @project = Project.find(params[:id])
  end

  def load_users
    designations = ['UI/UX Lead', 'UI/UX Designer', 'Senior UI/UX Designer',
      'Software Engineer', 'Senior Software Engineer', 'Team Lead',
      'QA Engineer', 'Senior QA Engineer', 'QA Lead', 'Intern']
    designation_ids = Designation.where(:name.in => designations).pluck(:id)
    @users = User.approved.where("employee_detail.designation_id" => {"$in" => designation_ids}).order([:email, :asc])
  end
end
