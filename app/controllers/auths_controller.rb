# Provides an authentication service.
#
# Lets external services such as tmc-comet check whether a given (username, password) or
# (username, session_id) is valid.
class AuthsController < ApplicationController
  OK_MESSAGE = 'OK'.freeze
  FAIL_MESSAGE = 'FAIL'.freeze

  skip_authorization_check
  skip_before_action :verify_authenticity_token

  def show
    if params[:username].present? && params[:session_id].present?
      return render text: Rails.cache.fetch("auths_controller_user_#{params[:username]}_session_#{params[:session_id]}", expires_in: 1.hour) do
        user = User.find_by(login: params[:username])
        # Allows using oauth2 tokens of the new api for authenticating
        if user && Doorkeeper::AccessToken.find_by(resource_owner_id: user.id, token: params[:session_id])
          OK_MESSAGE
        elsif user && find_session_by_id(params[:session_id]).andand.belongs_to?(user)
          OK_MESSAGE
        else
          FAIL_MESSAGE
        end
      end
    end

    user = User.find_by(login: params[:username])
    msg = if user && params[:password].present? && user.has_password?(params[:password])
            OK_MESSAGE
          else
            FAIL_MESSAGE
          end

    respond_to do |format|
      format.any(:html, :text) do # Work around bug in HTTP library used by tmc-comet and accept HTML mime type
        render text: msg
      end
      format.json do
        render json: { status: msg }
      end
    end
  end

  private

  def find_session_by_id(sid)
    # Can't say Session.find_by_session_id because of a nasty metaprogramming hax in AR's superclass.
    Session.where(session_id: sid).first
  end
end
