class ArticlesController < ApplicationController
  
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create

  before_action :authenticate_user!
  def new
    @article = Article.new
  end

  def create
    @article = Article.new(articles_params)
    if @article.save
      flash[:notice] = "Article created Succesfully" 
      redirect_to attachments_path
    else
      render action: 'new'
    end
  end

  def show
    @article = Article.find(params[:id])
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    if @article.update_attributes(articles_params)
      flash[:notice] = "Article updated Succesfully" 
      redirect_to attachments_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @article = Article.find(params[:id])
    flash[:notice] = @article.destroy ? "Article deleted Succesfully" : "Error in deleting article"
    redirect_to attachments_path
  end

  private
  def articles_params
    params.require(:article).permit(:title, :content, :is_published)
  end

end
