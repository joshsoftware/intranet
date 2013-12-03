class HomeController < ApplicationController
  def index
    @projects = Project.all_active
    @bonusly_updates = get_bonusly_updates
    render stream: true
  end

  def get_bonusly_updates
    bonus = Api::Bonusly.new
    messages = bonus.all_bonusly_messages
    messages
  end

  def calendar
    
  end
end
