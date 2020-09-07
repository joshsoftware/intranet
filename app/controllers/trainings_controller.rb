class TrainingsController < ApplicationController
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!

  def index
    @trainings = Training.training_only.asc(:date)
  end

  def new
    @training = Training.new()
  end

  def create
    @training = Training.new(safe_params)
    if @training.save
      create_file_attachments(params)
      flash[:success] = "Training Record created Successfully"
      redirect_to trainings_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @training.update(safe_params)
      create_file_attachments(params)
      redirect_to trainings_path
    else
      flash[:error] = "Training record updation failed"
      render 'edit'
    end
  end

  def show
  end

  def destroy
    if @training.destroy
     flash[:notice] = "Training record deleted Successfully"
    else
     flash[:notice] = "Error in deleting training record"
    end
     redirect_to trainings_path
  end

  def video_render
  end

  private
  def safe_params
    params.require(:training).permit(:subject, :objectives, :date, :showcase_on_website, :venue, :duration, :video, :blog_link, :trainer_ids => [],
      :chapters_attributes => [:id, :chapter_number, :subject, :objectives, :video, :blog_link, :duration, :_destroy, :trainer_ids => []])
  end

  def create_file_attachments(params)
    params[:training][:photos].try(:each) do |photo|
      @training.file_attachments.create!(:doc => photo, type: 'photo')
    end
    params[:training][:ppts].try(:each) do |ppt|
      @training.file_attachments.create!(:doc => ppt, type: 'ppt')
    end
    params[:training][:chapters_attributes].try(:each) do |chapter_attributes|
      next if chapter_attributes[1][:_destroy] == '1'
      chapter = @training.chapters.find_by(chapter_number: chapter_attributes[1]['chapter_number'])
      chapter_attributes[1][:photos].try(:each) do |photo|
        chapter.file_attachments.create!(:doc => photo, type: 'photo')
      end
      chapter_attributes[1][:ppts].try(:each) do |ppt|
        chapter_attributes.file_attachments.create!(:doc => ppt, type: 'ppt')
      end
    end
  end
end
