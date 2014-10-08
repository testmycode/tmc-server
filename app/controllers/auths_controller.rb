# Provides an authentication service.
#
# Lets external services such as tmc-comet check whether a given (username, password) or
# (username, session_id) is valid.
class AuthsController < ApplicationController
  skip_authorization_check
  skip_before_filter :verify_authenticity_token

  def show
    msg = "FAIL"

    user = User.find_by_login(params[:username])
    if user
      if !params[:password].blank? && user.has_password?(params[:password])
        msg = "OK"
      elsif !params[:session_id].blank? && find_session_by_id(params[:session_id]).andand.belongs_to?(user)
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

private
  def find_session_by_id(sid)
    # Can't say Session.find_by_session_id because of a nasty metaprogramming hax in AR's superclass.
    Session.where(:session_id => sid).first
  end
end
