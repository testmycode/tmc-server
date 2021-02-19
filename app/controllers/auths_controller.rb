# frozen_string_literal: true

# Provides an authentication service.
class AuthsController < ApplicationController
  OK_MESSAGE = 'OK'
  FAIL_MESSAGE = 'FAIL'

  skip_authorization_check
  skip_before_action :verify_authenticity_token

  def show
    if params[:username].present? && params[:session_id].present?
      user = User.find_by(login: params[:username])
      user ||= User.find_by('lower(email) = ?', params[:username].downcase)
      # Allows using oauth2 tokens of the new api for authenticating
      res = if user && Doorkeeper::AccessToken.find_by(resource_owner_id: user.id, token: params[:session_id])
        OK_MESSAGE
      elsif user && find_session_by_id(params[:session_id])&.belongs_to?(user)
        OK_MESSAGE
      else
        FAIL_MESSAGE
      end
      return render plain: res
    end

    user = User.find_by(login: params[:username])
    user ||= User.find_by('lower(email) = ?', params[:username].downcase)
    msg = if user && params[:password].present? && user.has_password?(params[:password])
      OK_MESSAGE
    else
      FAIL_MESSAGE
    end

    respond_to do |format|
      format.any(:html, :text) do # Work around bug in HTTP library used by tmc-comet and accept HTML mime type
        render plain: msg
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
