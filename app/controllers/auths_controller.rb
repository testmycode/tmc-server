class AuthsController < ApplicationController
  skip_authorization_check
  skip_before_filter :verify_authenticity_token

  def show
    msg = "FAIL"

    user = User.find_by_login(params[:username])
    if user
      if params[:password] && user.has_password?(params[:password])
        msg = "OK"
      elsif params[:session_id] && Session.find_by_session_id(params[:session_id]).andand.belongs_to?(user)
        msg = "OK"
      end
    end

    respond_to do |format|
      format.any(:html, :text) do # Work around bug in HTTP library used by tmc-comet and accept HTML mime type
        render :text => msg
      end
      format.json do
        render :json => {:status => msg}.to_json
      end
    end
  end
end