class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  include SessionsHelper

  before_filter :is_authenticated?, :only => [
    :edit, :update, :new, :delete, :destroy
  ]

  before_filter :set_default_url_options


  def is_authenticated?
    if session[:user_id] == nil
      redirect_to :courses
    end
  end

  def set_default_url_options
    Rails.application.routes.default_url_options[:host]=request.host_with_port
  end
end
