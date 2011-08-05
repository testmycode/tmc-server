class SessionsController < ApplicationController

  skip_authorization_check

  def create
    user = User.authenticate(params[:session][:login],
                             params[:session][:password])

    redirect_params = {}
    if user.nil?
      redirect_params = {:alert => "Login or password incorrect. Try again."}
    elsif !user.administrator?
      redirect_params = {:alert => "Become an administrator and try again."}
    else
      sign_in user
    end

    try_to_redirect_back(redirect_params)
  end

  def destroy
    sign_out
    try_to_redirect_back(:notice => 'Goodbye')
  end

private
  def try_to_redirect_back(redirect_params = {})
    if not request.env['HTTP_REFERER'].blank?
      redirect_to :back, redirect_params
    else
      redirect_to root_path, redirect_params
    end
  end

end
