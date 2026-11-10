# typed: strict
# frozen_string_literal: true

# Handles login and logout.
class SessionsController < ApplicationController
  skip_authorization_check

  sig { void }
  def new
    session[:return_to] ||= url_from(params[:return_to])
    if signed_in?
      path = session[:return_to] ||= root_path
      redirect_to path
    end
  end

  sig { void }
  def create
    user, status = User.authenticate_with_status(params[:session][:login], params[:session][:password])

    case status
    when :accepted
      sign_in T.must(user)
      try_to_redirect_back
    when :unavailable
      try_to_redirect_incorrect_login(alert: 'Login is temporarily unavailable. Please try again shortly.')
    when :misconfigured
      try_to_redirect_incorrect_login(alert: 'Your account needs manual attention before you can log in. Please contact support.')
    else
      try_to_redirect_incorrect_login(alert: 'Invalid credentials. Try again.')
    end
  end

  sig { void }
  def destroy
    sign_out
    try_to_redirect_back(notice: 'Goodbye')
  end

  private
    sig { params(redirect_params: T::Hash[Symbol, T.untyped]).void }
    def try_to_redirect_back(redirect_params = {})
      if session[:return_to].present?
        return_to = session.delete(:return_to)
        redirect_to return_to, redirect_params
      elsif request.env['HTTP_REFERER'].present?
        redirect_to request.env['HTTP_REFERER'], redirect_params
      elsif request.referer.present?
        redirect_to request.referer, redirect_params
      else
        redirect_to root_path, redirect_params
      end
    end

    sig { params(redirect_params: T::Hash[Symbol, T.untyped]).void }
    def try_to_redirect_incorrect_login(redirect_params = {})
      if request.referer.present?
        redirect_to request.referer, redirect_params
      elsif request.env['HTTP_REFERER'].present?
        redirect_to request.env['HTTP_REFERER'], redirect_params
      else
        redirect_to login_path, redirect_params
      end
    end
end
