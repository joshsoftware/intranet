class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :is_user_exist?, only: :projects
  def projects
    user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
    projects = user.projects.pluck(:name) unless user.nil?
    @slack.show_projects(projects, params['channel_id']) unless projects.nil?
    if user.nil?
      render json: { text: 'You are not register as slack user' }, status: 401
    else
      if projects.blank?
        render json: { text: 'You are not working on any project' }
      else
        render json: { text: '' }, status: 200
      end
    end
  end

  private

  def is_user_exist?
    @slack = SlackBot.new
    user = User.where("public_profile.slack_handle" => params['user_id'])
    return unless user.first.nil?
    email = @slack.get_user_info(params['user_id'])
    exists_user = User.where(email: email)
    exists_user.first.public_profile.update_attribute(:slack_handle, params['user_id'])
  end
end
