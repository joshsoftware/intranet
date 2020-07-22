class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!, only: [:info]
  skip_before_filter :verify_authenticity_token

  def info
    render json: {} and return if current_user.blank?
    render json: { id: current_user.id.to_s,
      email: current_user.email,
      name: current_user.name
    }
  end

  def index
    render json: { users: User.employees.as_json(user_info_fields) }
  end

  private

  def user_info_fields
    {
      only: [:_id, :name, :email, :role],
      methods: [:name],
      include: {
        public_profile: {
          only: [
            :github_handle, :gitlab_handle, :bitbucket_handle]
        }
      }
    }
  end
end
