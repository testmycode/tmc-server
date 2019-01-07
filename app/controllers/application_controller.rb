# frozen_string_literal: true

require 'version'
require 'twitter-bootstrap-breadcrumbs'

# Base class for all controllers.
#
# Includes common parts like handling some exceptions as well as
# various utility methods.
class ApplicationController < ActionController::Base
  include BreadCrumbs

  helper :all

  add_breadcrumb 'TMC', :root_path

  layout :select_layout

  protect_from_forgery
  include BootstrapFlashHelper
  include FlashBlockHelper
  include SessionsHelper
  include BreadcrumbHelpers
  include EmbeddableHelper
  include AuthorizeCollectionHelper
  include ApplicationHelper
  check_authorization

  rescue_from CanCan::AccessDenied do |_exception|
    if current_user.guest?
      redirect_to(login_path(return_to: return_to_link))
    else
      respond_access_denied
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_with_error(message = 'Not found', 404, exception)
  end

  rescue_from ActionController::MissingFile do |exception|
    respond_with_error(message = 'File not found', 404, exception)
  end

  before_action :set_default_url_options
  before_action :check_api_version
  before_action :set_bare_layout
  before_action :set_controller_and_action_name
  before_action :setup_rack_mini_profiler

  def url_options
    if @bare_layout
      { bare_layout: '1' }.merge(super)
    else
      super
    end
  end

  private

    def current_ability
      @current_ability ||= ::Ability.new(current_user)
    end

    def set_default_url_options
      Rails.application.routes.default_url_options[:host] = request.host_with_port
    end

    def check_api_version
      if should_check_api_version?
        if params[:api_version].blank?
          return respond_with_error('Please update the TMC client. No API version received from client.', 404, nil, obsolete_client: true)
        elsif params[:api_version].to_s != ApiVersion::API_VERSION.to_s
          return respond_with_error("Please update the TMC client. API version #{ApiVersion::API_VERSION} required but got #{params[:api_version]}", 404, nil, obsolete_client: true)
        end

        if params[:client].present? # Client and client version checks are optional
          begin
            check_client_version(params[:client], params[:client_version])
          rescue StandardError
            return respond_with_error($!.message, 404, nil, obsolete_client: true)
          end
        end
      end
    end

    def check_client_version(client_name, client_version)
      begin
        client_version = Version.new(client_version) unless client_version.nil?
      rescue StandardError
        raise "Invalid version string: #{client_version}"
      end

      valid_clients = SiteSetting.value('valid_clients')
      if valid_clients.is_a?(Enumerable)
        vc = valid_clients.find { |c| c['name'] == client_name }
        raise 'Invalid TMC client.' if vc.nil?

        if !client_version.nil? && vc['min_version'].present?
          raise 'Please update the TMC client.' if client_version < Version.new(vc['min_version'])
        else
          return # without version check
        end
      end
    end

    def should_check_api_version?
      params[:format] == 'json' &&
        controller_name != 'stats' &&
        controller_name != 'auths' &&
        !(controller_name == 'feedback_answers' && action_name == 'index') &&
        !(controller_path.starts_with? 'api')
    end

    def set_bare_layout
      @bare_layout = !!params[:bare_layout]
    end

    def set_controller_and_action_name
      @controller_name = controller_name
      @action_name = action_name
    end

    def setup_rack_mini_profiler
      if current_user && current_user.administrator? && params[:profile]
        Rack::MiniProfiler.authorize_request
      end
    end

    def unauthorized!(message = nil)
      raise CanCan::AccessDenied, message
    end

    def unauthorize_guest!(message = 'Authentication required')
      unauthorized!(message) if current_user.guest?
    end

    def only_admins!
      unauthorized! unless current_user.administrator?
    end

    def authorization_skip!
      authorize! :read, nil
    end

    def respond_not_found(msg = 'Not Found')
      respond_with_error(msg, 404)
    end

    def respond_access_denied(msg = 'Access denied')
      respond_with_error(msg, 401)
    end

    def respond_with_error(msg, code = 500, exception = nil, extra_json_keys = {})
      respond_to do |format|
        format.html do
          render 'shared/respond_with_error',
                 locals: { message: ERB::Util.html_escape(msg), exception: exception },
                 layout: true,
                 status: code
        end
        format.json do
          if code == 401
            # To support older TmcNetBeans versions using faulty http basic auth
            if client_supports_http_basic_auth?
              response.headers['WWW-Authenticate'] = "Basic realm=\"#{msg}\""
              render json: { error: msg }.merge(extra_json_keys), status: code
            else
              render json: { error: msg }.merge(extra_json_keys), status: :forbidden
            end
          else
            render json: { error: msg }.merge(extra_json_keys), status: code
          end
        end
        format.text { render text: 'ERROR: ' + msg, status: code }
        format.zip { render text: msg, status: code, content_type: 'text/plain' }
      end
    end

    # To support older versions of tmc-netbeans-plugin
    def client_supports_http_basic_auth?
      return true if params[:client].blank?
      client = params[:client]
      client_version = begin
        Version.new(params['client_version']) if params['client_version'].present?
      rescue StandardError
      end
      !(client == 'netbeans_plugin' && client_version < Version.new('0.8.0'))
    end

    def select_layout
      if params[:bare_layout]
        'bare'
      else
        'application'
      end
    end

    def params_starting_with(prefix, permitted, options = {})
      options = {
        remove_prefix: false
      }.merge(options)

      permitted = permitted.map { |f| prefix + f } unless permitted == :all

      result = Hash[params.select do |k, v|
        k.start_with?(prefix) && v.present? && (permitted == :all || permitted.include?(k))
      end]
      if options[:remove_prefix]
        result = Hash[result.map { |k, v| [k.sub(/^#{prefix}/, ''), v] }]
      end
      result
    end

    # To be called from a respond_to on csv.
    # http://stackoverflow.com/questions/94502/in-rails-how-to-return-records-as-a-csv-file
    def render_csv(options = {})
      options = {
        filename: action_name
      }.merge(options)

      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Expires'] = 'Thu, 01 Dec 1994 16:00:00 GMT'

      if /msie/i.match?(request.env['HTTP_USER_AGENT'])
        headers['Pragma'] = 'public'
        headers['Content-type'] = 'text/plain'
      else
        headers['Content-Type'] ||= 'text/csv'
      end
      headers['Content-Disposition'] = "attachment; filename=\"#{options[:filename]}\""

      render_options = {
        layout: false
      }.merge(options)
      render_options.delete(:filename)

      render render_options
    end

    def wrap_transaction
      ActiveRecord::Base.transaction(requires_new: true) do
        yield
      end
    end
end
