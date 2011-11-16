class ApplicationController < ActionController::Base
  helper :all
  
  protect_from_forgery

  include SessionsHelper
  check_authorization
  
  rescue_from CanCan::AccessDenied do |exception|
    respond_access_denied
  end unless Rails::env == 'test'  # for clearer error messages

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_with_error(exception.message, 404)
  end

  before_filter :set_default_url_options

private

  def current_ability
    @current_ability ||= Ability.new(current_user, session)
  end

  def set_default_url_options
    Rails.application.routes.default_url_options[:host]=request.host_with_port
  end
  
  def respond_not_found(msg = 'Not Found')
    respond_with_error(msg, 404)
  end
  
  def respond_access_denied(msg = 'Access denied')
    respond_with_error(msg, 403)
  end
  
  def respond_with_error(msg, code = 500)
    respond_to do |format|
      format.html { render :text => '<p class="error">' + ERB::Util.html_escape(msg) + '</p>', :layout => true, :status => 403 }
      format.json { render :json => { :error => msg }, :status => 403 }
    end
  end
end
