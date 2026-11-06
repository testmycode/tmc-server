# typed: strict
# frozen_string_literal: true

require 'version'
require 'twitter_bootstrap_breadcrumbs'

# Base class for all controllers.
#
# Includes common parts like handling some exceptions as well as
# various utility methods.
class ApplicationController < ActionController::Base
  extend T::Sig
  include BreadCrumbs

  helper :all

  add_breadcrumb 'TMC', :root_path

  layout :select_layout

  protect_from_forgery
  include BootstrapFlashHelper
  include FlashBlockHelper
  include SessionsHelper
  include AuthorizeCollectionHelper
  include ApplicationHelper
  check_authorization

  rescue_from CanCan::AccessDenied do |_exception|
    T.bind(self, ApplicationController)
    if current_user.guest?
      redirect_to(login_path(return_to: return_to_link))
    else
      respond_forbidden
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    T.bind(self, ApplicationController)
    respond_with_error('Not found', 404, exception)
  end

  rescue_from ActionController::MissingFile do |exception|
    T.bind(self, ApplicationController)
    respond_with_error('File not found', 404, exception)
  end

  rescue_from Rack::Timeout::RequestTimeoutException do |exception|
    T.bind(self, ApplicationController)
    respond_with_error('Request timed out', 504, exception) # status code 408 would be the correct status code, but when receiving 408 Firefox retries 10 times and then states the connection was reset instead of showing our error
  end

  rescue_from Rack::Timeout::RequestTimeoutError do |exception|
    T.bind(self, ApplicationController)
    respond_with_error('Request timed out', 504, exception) # status code 408 would be the correct status code, but when receiving 408 Firefox retries 10 times and then states the connection was reset instead of showing our error
  end

  before_action :set_default_url_options
  before_action :check_api_version
  before_action :set_bare_layout
  before_action :set_controller_and_action_name
  before_action :setup_rack_mini_profiler

  sig { void }
  def initialize
    super
    # Declared here because the breadcrumb helpers read them; subclasses assign them.
    @organization = T.let(nil, T.nilable(Organization))
    @course = T.let(nil, T.nilable(Course))
    @exercise = T.let(nil, T.nilable(Exercise))
    @submission = T.let(nil, T.nilable(Submission))
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def url_options
    if @bare_layout
      { bare_layout: '1' }.merge(super)
    else
      super
    end
  end

  private
    sig { returns(::Ability) }
    def current_ability
      @current_ability ||= T.let(::Ability.new(current_user), T.nilable(::Ability))
    end

    sig { void }
    def set_default_url_options
      Rails.application.routes.default_url_options[:host] = request.host_with_port
    end

    sig { void }
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
            respond_with_error($!.message, 404, nil, obsolete_client: true)
          end
        end
      end
    end

    sig { params(client_name: T.untyped, client_version: T.untyped).void }
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
          nil # without version check
        end
      end
    end

    sig { returns(T::Boolean) }
    def should_check_api_version?
      params[:format] == 'json' &&
        controller_name != 'stats' &&
        controller_name != 'auths' &&
        !(controller_name == 'feedback_answers' && action_name == 'index') &&
        !(controller_path.starts_with? 'api')
    end

    sig { void }
    def set_bare_layout
      @bare_layout = T.let(!!params[:bare_layout], T.nilable(T::Boolean))
    end

    sig { void }
    def remove_x_frame_options_header_when_bare_layout
      response.headers.except! 'X-Frame-Options' if @bare_layout
    end

    sig { void }
    def set_controller_and_action_name
      @controller_name = T.let(controller_name, T.nilable(String))
      @action_name = T.let(action_name, T.nilable(String))
    end

    sig { void }
    def setup_rack_mini_profiler
      if current_user.administrator?
        Rack::MiniProfiler.authorize_request
      end
    end

    sig { params(message: T.nilable(String)).returns(T.noreturn) }
    def unauthorized!(message = nil)
      raise CanCan::AccessDenied, message
    end

    sig { params(message: String).void }
    def unauthorize_guest!(message = 'Authentication required')
      unauthorized!(message) if current_user.guest?
    end

    sig { void }
    def only_admins!
      unauthorized! unless current_user.administrator?
    end

    sig { void }
    def authorization_skip!
      authorize! :read, nil
    end

    sig { params(msg: String).void }
    def respond_not_found(msg = 'Not Found')
      respond_with_error(msg, 404)
    end

    sig { params(msg: String).void }
    def respond_forbidden(msg = 'Forbidden')
      respond_with_error(msg, 403)
    end

    sig { params(msg: String).void }
    def respond_unauthorized(msg = 'Authentication required')
      respond_with_error(msg, 401)
    end

    sig { params(msg: String, code: Integer, exception: T.nilable(Exception), extra_json_keys: T::Hash[Symbol, T.untyped]).void }
    def respond_with_error(msg, code = 500, exception = nil, extra_json_keys = {})
      respond_to do |format|
        format.html do
          render 'shared/respond_with_error',
                 locals: { message: ERB::Util.html_escape(msg), exception: exception },
                 layout: true,
                 status: code
        end
        format.json do
          if code == 401 || code == 403
            # To support older TmcNetBeans versions using faulty http basic auth
            if client_supports_http_basic_auth?
              response.headers['WWW-Authenticate'] = "Basic realm=\"#{msg}\""
              render json: { error: msg }.merge(extra_json_keys), status: code
            else
              render json: { error: msg }.merge(extra_json_keys), status: :forbidden if code == 403
              render json: { error: msg }.merge(extra_json_keys), status: :unauthorized if code == 401
            end
          else
            render json: { error: msg }.merge(extra_json_keys), status: code
          end
        end
        format.text { render plain: 'ERROR: ' + msg, status: code }
        format.zip { render plain: msg, status: code, content_type: 'text/plain' }
      end
    end

    # To support older versions of tmc-netbeans-plugin
    sig { returns(T::Boolean) }
    def client_supports_http_basic_auth?
      return true if params[:client].blank?
      client = params[:client]
      client_version = begin
        Version.new(params['client_version']) if params['client_version'].present?
      rescue StandardError
      end
      !(client == 'netbeans_plugin' && T.must(client_version) < Version.new('0.8.0'))
    end

    sig { returns(String) }
    def select_layout
      if params[:bare_layout]
        'bare'
      else
        'application'
      end
    end

    # permitted: :all, or the field names without the prefix.
    sig { params(prefix: String, permitted: T.any(Symbol, T::Array[String]), options: T::Hash[Symbol, T.untyped]).returns(T::Hash[String, T.untyped]) }
    def params_starting_with(prefix, permitted, options = {})
      options = {
        remove_prefix: false
      }.merge(options)

      permitted = permitted.map { |f| prefix + f } if permitted.is_a?(Array)

      result = Hash[params.select do |k, v|
        k.start_with?(prefix) && v.present? && (permitted == :all || (permitted.is_a?(Array) && permitted.include?(k)))
      end.permit(permitted)]
      if options[:remove_prefix]
        result = result.transform_keys { |k| k.sub(/^#{prefix}/, '') }
      end
      result
    end

    # To be called from a respond_to on csv.
    # http://stackoverflow.com/questions/94502/in-rails-how-to-return-records-as-a-csv-file
    sig { params(options: T::Hash[Symbol, T.untyped]).void }
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

    sig { params(block: T.proc.void).void }
    def wrap_transaction(&block)
      ActiveRecord::Base.transaction(requires_new: true, &block)
    end

    sig { void }
    def add_organization_breadcrumb
      organization = T.must(@organization)
      add_breadcrumb "Organization #{organization.name}", organization_path(organization)
    end

    sig { void }
    def add_course_breadcrumb
      add_organization_breadcrumb
      course = T.must(@course)
      add_breadcrumb "Course #{course.name}", organization_course_path(@organization, course)
    end

    sig { void }
    def add_exercise_breadcrumb
      exercise = @exercise || @submission&.exercise
      if exercise
        add_breadcrumb "Exercise #{exercise.name}", exercise_path(exercise)
      elsif @submission&.exercise_name
        add_breadcrumb "(deleted exercise #{@submission.exercise_name}"
      else
        raise 'Neither @exercise nor @submission.exercise_name set'
      end
    end

    sig { void }
    def add_submission_breadcrumb
      submission = T.must(@submission)
      add_breadcrumb "Submission ##{submission.id}", submission_path(submission)
    end
end
