class PoliciesController < ApplicationController
  
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create

  before_action :authenticate_user!
  def new
    @policy = Policy.new
  end

  def create
    @policy = Policy.new(policies_params)
    if @policy.save
      flash[:notice] = "Policy created Successfully" 
      redirect_to attachments_path
    else
      render action: 'new'
    end
  end

  def show
    @policy = Policy.find(params[:id])
  end

  def edit
    @policy = Policy.find(params[:id])
  end

  def update
    @policy = Policy.find(params[:id])
    if @policy.update_attributes(policies_params)
      flash[:notice] = "Policy updated Successfully" 
      redirect_to attachments_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @policy = Policy.find(params[:id])
    flash[:notice] = @policy.destroy ? "Policy deleted Successfully" : "Error in deleting policy"
    redirect_to attachments_path
  end

  private
  def policies_params
    params.require(:policy).permit(:title, :content, :is_published)
  end

end
