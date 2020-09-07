class ShowcaseEventsController < ApplicationController
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!

  def index
    @showcase_events = ShowcaseEvent.asc(:date)
  end

  def new
    @showcase_event = ShowcaseEvent.new()
    @showcase_event.showcase_event_applications.build
    @showcase_event.showcase_event_teams.build
    @showcase_event_applications = @showcase_event.showcase_event_applications
  end

  def create
    @showcase_event = ShowcaseEvent.new(safe_params)
    if @showcase_event.save
      params[:showcase_event][:photos].try(:each) do |photo|
        @showcase_event.file_attachments.create!(:doc => photo, type: 'photo')
      end
      flash[:success] = "Event created Successfully"
      redirect_to showcase_events_path
    else
      render 'new'
    end
  end

  def edit
    @showcase_event_applications = @showcase_event.showcase_event_applications
  end

  def update
    if @showcase_event.update(safe_params)
      params[:showcase_event][:photos].try(:each) do |photo|
        @showcase_event.file_attachments.create!(:doc => photo, type: 'photo')
      end
      redirect_to edit_showcase_event_path(@showcase_event)
    else
      @showcase_event_applications = @showcase_event.showcase_event_applications
      flash[:error] = "Event updation failed"
      render 'edit'
    end
  end

  def show
    @showcase_event_applications = @showcase_event.showcase_event_applications
  end

  def destroy
    if @showcase_event.destroy
     flash[:notice] = "Event deleted Successfully"
    else
     flash[:notice] = "Error in deleting event"
    end
     redirect_to showcase_events_path
  end

  private
  def safe_params
    params.require(:showcase_event).permit(:name, :type, :url, :description, :date, :venue, :video,
      :showcase_on_website, showcase_event_applications_attributes: %i[id name description domain _destroy], :user_ids => [],
      showcase_event_teams_attributes: [:id, :name, :showcase_event_application_id, :proposed_solution,
      :repository_link, :demo_link, :_destroy, :member_ids => [], technology_details_attributes: %i[id name version _destroy]])
  end
end
