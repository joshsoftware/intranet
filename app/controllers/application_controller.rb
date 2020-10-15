class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?

  protect_from_forgery with: :exception

  before_filter :store_location
  before_filter :check_for_light, :check_for_screamout
  skip_before_filter :verify_authenticity_token, only: :blog_publish_hook
  after_filter :cors_set_access_control_headers
  def store_location
    unless INVALID_REDIRECTIONS.include?(request.fullpath) && request.xhr?
      if session[:previous_url].blank? || session[:previous_url] == '/'
        session[:previous_url] = request.fullpath
      end
    end

    return session[:previous_url]
  end

  def after_sign_in_path_for(resource)
    if current_user.role == ROLE[:consultant]
      public_profile_user_path(current_user)
    else
      INVALID_REDIRECTIONS.include?(session[:previous_url]) ? root_path : session[:previous_url]
    end
  end

  def check_for_light
    return if params[:controller].eql?('light/newsletters') and params[:action].eql?('web_version')
    if request.url.include?('newsletter') and !current_user.try(:role).in?(['Admin', 'HR', 'Super Admin'])
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to main_app.root_url and return
    end
  end

  def check_for_screamout
    if params[:controller].eql?('screamout/contents') and [ROLE[:consultant]].include?(current_user.try(:role))
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to main_app.public_profile_user_path(current_user) and return
    end
  end

  def blog_publish_hook
    UserMailer.delay.new_blog_notification(params)
    render nothing: true
  end

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  end

  rescue_from CanCan::AccessDenied do |exception|
    if [ROLE[:consultant]].include?(current_user.try(:role))
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to main_app.public_profile_user_path(current_user)
    else
      redirect_to main_app.root_url, :alert => exception.message
    end
  end

end
