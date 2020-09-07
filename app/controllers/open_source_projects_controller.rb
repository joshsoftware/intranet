class OpenSourceProjectsController < ApplicationController
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!

  def index
  end

  def new
    @open_source_project = OpenSourceProject.new()
  end

  def create
    @open_source_project = OpenSourceProject.new(safe_params)
    if @open_source_project.save
      flash[:success] = "Open Source Project created Successfully"
      redirect_to open_source_projects_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @open_source_project.update(safe_params)
      redirect_to open_source_projects_path
    else
      render 'edit'
    end
  end

  def show
    @team_members = @open_source_project.users
  end

  def destroy
    if @open_source_project.destroy
     flash[:notice] = "Open Source Project deleted Successfully"
    else
     flash[:notice] = "Error in deleting project"
    end
     redirect_to open_source_projects_path
  end

  private
  def safe_params
    params.require(:open_source_project).permit(:name, :image, :url, :description, :case_study,
      :showcase_on_website, :user_ids => [], technology_details_attributes: %i[id name version _destroy])
  end
end
