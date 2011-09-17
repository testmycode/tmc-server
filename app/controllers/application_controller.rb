class ApplicationController < ActionController::Base
  helper :all
  
  protect_from_forgery

  include SessionsHelper
  check_authorization
  
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { render :text => '<p class="error">Access denied.</p>', :layout => true }
      format.json { render :json => { :error => 'Access denied.' } }
    end
  end unless Rails::env == 'test'  # for clearer error messages

  before_filter :set_default_url_options

protected

  def current_ability
    @current_ability ||= Ability.new(current_user, session)
  end

  def set_default_url_options
    Rails.application.routes.default_url_options[:host]=request.host_with_port
  end
  
  def respond_not_found
    raise ActionController::RoutingError.new('Not Found')
  end
end
