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

  def non_confirmed(user)
    session[:non_confirmed_user_id] = user.id
  end

  def user_from_non_confirmed_session
    User.find_by_id(session[:non_confirmed_user_id])
  end

  def clear_non_confirmed_session_for(user)
    session[:non_confirmed_user_id] = nil
    @current_user = Guest.new
    reset_session
  end

  private

  def user_from_session
    User.find_by_id(session[:user_id])
  end

  def user_from_basic_auth
    if request && request.authorization
      username, password = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
      if username && password
        User.authenticate(username, password)
      else
        nil
      end
    end
  end
end
