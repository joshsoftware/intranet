class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])
    if user
      if user.persisted?
        flash.notice = "Signed in Successfully!"
        sign_in user
        redirect_to public_profile_user_path(user)
      else
        session["devise.user_attributes"] = user.attributes
        flash.notice = "Contact Josh Software Admin for valid invitation request"
        redirect_to root_url
      end
    else
      flash.notice = "Contact Josh Software Admin for invitation request. Before leaving, Please logout from your google account."
      redirect_to root_url
    end
  end
end
