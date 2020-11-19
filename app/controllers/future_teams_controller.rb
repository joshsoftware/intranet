class FutureTeamsController < ApplicationController
  load_and_authorize_resource except: [:create, :index]
  before_action :authenticate_user!

  def new
    @future_team = FutureTeam.new()
  end

  def index
    @future_teams = FutureTeam.all
    respond_to do |format|
      format.html
      format.csv {send_data FutureTeam.to_csv()}
    end
  end

  def create
    @future_team = FutureTeam.new(strong_params)
    if @future_team.save
      flash[:success] = "Future Team Requirement created successfully!!!"
    else
      flash[:error] = @future_team.errors.full_messages.join("\n")
      render 'new' and return
    end
    redirect_to future_teams_path
  end

  def close
  end

  def edit
  end

  def update
    if params[:future_team][:current_status] == 'Closed'
      success_flash = "Future Team Requirement specifications has been closed successfully!!!"
      render_back = 'close'
    else
      success_flash = "Future Team Requirement specifications has been updated successfully!!!"
      render_back = 'edit'
    end
    if @future_team.update_attributes(strong_params)
      flash[:success] = success_flash
    else
      flash[:error] = @future_team.errors.full_messages.join("\n")
      render render_back and return
    end
    redirect_to future_teams_path and return
  end

  def destroy
    if @future_team.destroy
      flash[:notice] = "Future Team Requirement deleted Succesfully"
    else
      flash[:notice] = "Error in deleting Future Team Requirement"
    end
    redirect_to future_teams_path
  end

  def strong_params
    safe_params = [
                    :customer, :years_of_experience, :current_status,
                    :number_of_open_positions, :required_by_date,
                    :requirement_received_on, :skills => [], :proposed_candidates => []
                  ]
    params.require(:future_team).permit(*safe_params)
  end
end
