class ApplicationController < ActionController::Base
  helper :all
  
  protect_from_forgery

  include SessionsHelper
  check_authorization
  
  rescue_from CanCan::AccessDenied do |exception|
    respond_access_denied
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
  
  def respond_access_denied
    respond_to do |format|
      format.html { render :text => '<p class="error">Access denied.</p>', :layout => true, :status => 403 }
      format.json { render :json => { :error => 'Access denied.' }, :status => 403 }
    end
  end
end
