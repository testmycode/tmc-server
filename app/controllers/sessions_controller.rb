# frozen_string_literal: true

# Handles login and logout.
class SessionsController < ApplicationController
  skip_authorization_check

  def new
    session[:return_to] ||= params[:return_to]
    if signed_in?
      path = session[:return_to] ||= root_path
      redirect_to path
    end
  end

  def create
    begin
      clear_expired_sessions
    rescue StandardError
    end

    user = User.authenticate(params[:session][:login],
                             params[:session][:password])

    redirect_params = {}
    if user.nil?
      msg = 'Invalid credentials. Try again.'
      redirect_params = { alert: msg }
    else
      sign_in user
    end

    try_to_redirect_back(redirect_params)
  end

  def destroy
    sign_out
    try_to_redirect_back(notice: 'Goodbye')
  end

  private

    def try_to_redirect_back(redirect_params = {})
      if session[:return_to].present?
        return_to = session.delete(:return_to)
        redirect_to return_to, redirect_params
      elsif request.env['HTTP_REFERER'].present?
        redirect_back fallback_location: root_path
      elsif request.referer.present?
        redirect_to request.referer, redirect_params
      else
        redirect_to root_path, redirect_params
      end
    end

    def clear_expired_sessions
      Session.delete_expired
    end
end
