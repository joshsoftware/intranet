class ProjectsController < ApplicationController
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!
  before_action :load_project, except: [:index, :new, :create, :remove_team_member, :add_team_member, :generate_code]

  include RestfulAction

  def index
    @projects = Project.sort_by_position
    @projects.init_list!
    respond_to do |format|
      format.html
      format.csv { send_data @projects.to_csv }
    end
  end

  def new
    @company = Company.find(params[:company_id]) if params[:company_id]
    @project = Project.new(company: @company)
    @project.user_projects.build
  end

  def create
    @project = Project.new(safe_params)
    if @project.save
      flash[:success] = "Project created Succesfully"
      redirect_to projects_path
    else
      render 'new'
    end
  end

  def update
    return_value_of_add_team_member = return_value_of_remove_team_member = true
    return_value_of_add_team_member, return_value_of_remove_team_member = @project.add_or_remove_team_member(params) if params['project']['update_project'].present?
    if return_value_of_add_team_member && return_value_of_remove_team_member
      update_obj(@project, safe_params, projects_path)
    else
      flash[:error] = "Error unable to add or remove team member"
      render 'edit'
    end
  end

  def show
    @users = @project.users
    @managers = @project.managers
  end

  def destroy
    if @project.destroy
     flash[:notice] = "Project deleted Succesfully"
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
    :code_climate_coverage_snippet, :is_active, :is_free, :timesheet_mandatory, :ruby_version, :rails_version, :database, :database_version, :deployment_server,
    :deployment_script, :web_server, :app_server, :payment_gateway, :image_store, :index_server, :background_jobs, :sms_gateway,
    :other_frameworks,:other_details, :image, :url, :description, :case_study,:logo, :visible_on_website, :website_sequence_number,
    :code, :number_of_employees, :invoice_date, :company_id, :manager_ids => [])
  end

  def load_project
    @project = Project.find(params[:id])
  end
end
