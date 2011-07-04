class SessionsController < ApplicationController

# Sign in the user with correct password info and redirect to the user's show
# page. 

  def create
    user = User.authenticate(params[:session][:login],
                          params[:session][:password])
    if user.nil?
      @title = "Sign in"
      redirect_to courses_path, :notice => "Login or password incorrect. Try again."
    else
      sign_in user
      redirect_to :back
    end
  end

  def destroy
    sign_out
    redirect_to :back
  end

end
