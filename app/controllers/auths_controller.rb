class AuthsController < ApplicationController
  skip_authorization_check

  def show
    if User.authenticate(params[:username], params[:password]) != nil
      msg = "OK"
    else
      msg = "FAIL"
    end

    respond_to do |format|
      format.text do
        render :text => msg
      end
      format.html do
        render :text => msg, :layout => 'bare'
      end
      format.json do
        render :json => msg
      end
    end
  end
end