# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Callback for Telegram
  def telegram
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      flash[:notice] = "Signed in successfully via Telegram."
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.telegram_data"] = auth.except("extra")
      redirect_to new_user_registration_url, alert: "There was a problem signing you in via Telegram."
    end
  end

  def failure
    redirect_to root_path, alert: "Authentication failed."
  end
end
