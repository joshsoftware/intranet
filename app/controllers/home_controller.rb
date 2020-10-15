class HomeController < ApplicationController

  def index
    authorize! :read, :dashboard
    @projects = Project.all_active
    #@bonusly_updates = get_bonusly_updates
    feed = Feedjira::Feed.fetch_and_parse('http://blog.joshsoftware.com/feed/')
    @blog = feed.entries
    render stream: true
  end

  def store_url
    session[:previous_url] = request.fullpath
    redirect_to new_user_session_path
  end
  private

  def get_bonusly_updates
    bonus = Api::Bonusly.new(BONUSLY_TOKEN)
    bonus.bonusly_messages
  end

end
