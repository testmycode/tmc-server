class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  include SessionsHelper

  before_filter :check_authenticated, :only => [
    :edit, :update, :new, :delete, :destroy
  ]

  before_filter :set_default_url_options


protected

  def check_authenticated
    if session[:user_id] == nil
      redirect_to :courses
    end
  end

  def logged_in_as_administrator?
    current_user != nil && current_user.administrator?
  end

  def set_default_url_options
    Rails.application.routes.default_url_options[:host]=request.host_with_port
  end
end
