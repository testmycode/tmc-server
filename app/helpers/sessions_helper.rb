module SessionsHelper

  def sign_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_api_call || user_from_session || Guest.new
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
    User.find_by_id(session[:user_id])
  end
  
  def user_from_api_call
    username = params[:api_username]
    password = params[:api_password]
    
    if params[:format] == 'json' && username && password
      User.authenticate(username, password)
    else
      nil
    end
  end

end
