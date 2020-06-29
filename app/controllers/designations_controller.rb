class DesignationsController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create

  def index
    @designations = Designation.all.order_by([:name, :asc])
  end

  def new
    @designation = Designation.new
  end

  def create
    @designation = Designation.new(designation_params)
    if @designation.save
      flash[:success] = "Designation created Successfully"
      redirect_to designations_path
    else
      render action: 'new'
    end
  end

  def show
    @designation = Designation.find(params[:id])
  end

  def edit
    @designation = Designation.find(params[:id])
  end

  def update
    @designation = Designation.find(params[:id])
    if @designation.update_attributes(designation_params)
      flash[:success] = "Designation updated Successfully"
      redirect_to designations_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @designation = Designation.find(params[:id])
    flash[:notice] = @designation.destroy ? "Designation deleted Successfully" : "Error in deleting Designation"
    redirect_to designations_path
  end

  private

  def designation_params
    params.require(:designation).permit(:name, :parent_designation_id)
  end
end
