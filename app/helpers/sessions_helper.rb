# frozen_string_literal: true

module SessionsHelper
  def sign_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_basic_auth || user_from_session || Guest.new
  end

  def current_user=(user)
    if user.guest?
      sign_out
    else
      sign_in(user)
    end
  end

  def signed_in?
    !current_user.guest?
  end

  def sign_out
    session[:user_id] = nil
    @current_user = Guest.new
    reset_session
  end

  private

  def user_from_session
    User.find_by(id: session[:user_id])
  end

  def user_from_basic_auth
    if request&.authorization
      username, password = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
      User.authenticate(username, password) if username && password
    end
  end
end
