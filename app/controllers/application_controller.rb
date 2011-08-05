class ApplicationController < ActionController::Base
  helper :all
  
  protect_from_forgery

  include SessionsHelper
  check_authorization
  
  rescue_from CanCan::AccessDenied do |exception|
    render :text => '<p class="error">Access denied.</p>', :layout => true
  end unless Rails::env == 'test'  # for clearer error messages

  before_filter :set_default_url_options

protected

  def set_default_url_options
    Rails.application.routes.default_url_options[:host]=request.host_with_port
  end
end
