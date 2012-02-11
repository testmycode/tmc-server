class ApplicationController < ActionController::Base
  API_VERSION = 3 # To be incremented on BC-breaking changes
  
  helper :all
  
  layout :select_layout
  
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
  before_filter :check_api_version
  before_filter :set_bare_layout
  before_filter :set_controller_and_action_name

  def url_options
    if @bare_layout
      {:bare_layout => '1'}.merge(super)
    else
      super
    end
  end

private

  def current_ability
    @current_ability ||= Ability.new(current_user, session)
  end

  def set_default_url_options
    Rails.application.routes.default_url_options[:host] = request.host_with_port
  end
  
  def check_api_version
    if should_check_api_version?
      if params[:api_version].blank?
        respond_with_error("Please update the TMC client. No API version received from client.", 404, :obsolete_client => true)
      elsif params[:api_version] != API_VERSION.to_s
        respond_with_error("Please update the TMC client. API version #{API_VERSION} required but got #{params[:api_version]}", 404, :obsolete_client => true)
      end
    end
  end

  def should_check_api_version?
    params[:format] == 'json' &&
      controller_name != 'stats' &&
      !(controller_name == 'feedback_answers' && action_name == 'index')
  end
  
  def set_bare_layout
    @bare_layout = !!params[:bare_layout]
  end
  
  def set_controller_and_action_name
    @controller_name = controller_name
    @action_name = action_name
  end
  
  def respond_not_found(msg = 'Not Found')
    respond_with_error(msg, 404)
  end
  
  def respond_access_denied(msg = 'Access denied')
    respond_with_error(msg, 403)
  end
  
  def respond_with_error(msg, code = 500, extra_json_keys = {})
    respond_to do |format|
      format.html { render :text => '<p class="error">' + ERB::Util.html_escape(msg) + '</p>', :layout => true, :status => code }
      format.json { render :json => { :error => msg }.merge(extra_json_keys), :status => code }
      format.text { render :text => 'ERROR: ' + msg }
    end
  end
  
  def select_layout
    if params[:bare_layout]
      "bare"
    else
      "application"
    end
  end

  def params_starting_with(prefix, options = {})
    options = {
      :remove_prefix => false
    }.merge(options)

    result = params.select {|k, v| k.start_with?(prefix) }
    if options[:remove_prefix]
      result = Hash[result.map {|k, v| [k.sub(/^#{prefix}/, ''), v] }]
    end
    result
  end
  
end
