# typed: strict
# frozen_string_literal: true

require 'json'
require 'version'

module Api
  module V8
    class BaseController < ApplicationController
      extend T::Sig
      clear_respond_to
      respond_to :json

      #  before_action :doorkeeper_authorize!
      before_action :authenticate_user!
      before_action :check_client_version_api_v8
      skip_before_action :verify_authenticity_token

      rescue_from CanCan::AccessDenied do |e|
        T.bind(self, Api::V8::BaseController)
        if current_user.guest?
          respond_unauthorized(e.message)
        else
          respond_forbidden(e.message)
        end
      end

      rescue_from CoursesMoocFiTokenIntrospector::Unavailable do |e|
        T.bind(self, Api::V8::BaseController)
        Rails.logger.error("courses.mooc.fi token introspection unavailable: #{e.message}")
        respond_with_error('courses.mooc.fi could not verify your login right now. Try again later.', 503)
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        T.bind(self, Api::V8::BaseController)
        render json: errors_json(e.message), status: :not_found
      end

      sig { params(hash: T.untyped).void }
      def present(hash)
        if params[:pretty]
          render json: JSON.pretty_generate(hash)
        else
          render json: hash.to_json
        end
      end

      private
        sig { void }
        def authenticate_user!
          return if @current_user
          if (token = doorkeeper_token)
            @current_user = T.let(AccessTokenAuthentication.user_for(token), T.nilable(User))
            return respond_unauthorized('Invalid token') unless @current_user
            @auth_source = T.let(:handoff_token, T.nilable(Symbol)) if AccessTokenAuthentication.handoff?(token)
          elsif presented_doorkeeper_token
            return respond_unauthorized('Invalid token')
          elsif Rails.configuration.x.accept_courses_mooc_fi_tokens
            @current_user = CoursesMoocFiAuthentication.user_for(request)
            @auth_source = T.let(:courses_mooc_fi_token, T.nilable(Symbol)) if @current_user
          end
          @current_user ||= user_from_session_with_verified_csrf || Guest.new
        end

        # The session cookie authenticates API calls made from TMC's own pages, so those need the
        # CSRF token that the skipped verify_authenticity_token would otherwise demand.
        sig { returns(T.nilable(User)) }
        def user_from_session_with_verified_csrf
          user_from_session if verified_request?
        end

        # Before authenticate_user! has run (ApplicationController's own before_actions), this is a Guest.
        sig { returns(User) }
        def current_user
          @current_user || Guest.new
        end

        sig { returns(::Ability) }
        def current_ability
          @current_ability ||= T.let(::Ability.new(current_user, auth_source: @auth_source), T.nilable(::Ability))
        end

        # Narrows `points` (awarded points of `course`) to what the caller may see. Teachers see all;
        # anyone else only their own, none in exam mode or as a guest, and never those of exercises
        # that are hidden or hiding their results.
        # Raises CanCan::AccessDenied unless the caller may read the course.
        sig { params(course: Course, points: ActiveRecord::Relation).returns(ActiveRecord::Relation) }
        def visible_awarded_points(course, points)
          authorize! :read, course
          return points if can?(:teach, course)
          return points.none if current_user.guest? || !can?(:see_points, course)
          hidden_exercises = course.exercises.where(hidden: true).or(course.exercises.where(hide_submission_results: true))
          points.where(user_id: current_user.id)
                .where.not(name: AvailablePoint.where(exercise_id: hidden_exercises.select(:id)).select(:name))
        end

        # The API list fields of those `submissions` the current user may read.
        sig { params(submissions: ActiveRecord::Relation).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
        def readable_submission_fields(submissions)
          readable = submissions.preload(course: :organization).select { |sub| sub.readable_by?(current_user) }
          Submission.filter_fields!(readable, current_user)
        end

        sig { params(messages: T.any(String, T::Array[String])).returns(T::Hash[Symbol, T::Array[String]]) }
        def errors_json(messages)
          { errors: [*messages] }
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

        sig { params(msg: String, code: Integer, _exception: T.nilable(Exception), extra_json_keys: T::Hash[Symbol, T.untyped]).void }
        def respond_with_error(msg, code = 500, _exception = nil, extra_json_keys = {})
          respond_to do |format|
            format.html do
              render json: errors_json(msg), status: code
            end
            format.json do
              render json: { error: msg }.merge(extra_json_keys), status: code
            end
            format.text { render plain: 'ERROR: ' + msg, status: code }
            format.zip { render plain: msg, status: code, content_type: 'text/plain' }
          end
        end

        sig { void }
        def check_client_version_api_v8
          if should_check_for_client_version?
            begin
              check_client_minimum_version(params[:client], params[:client_version])
            rescue StandardError
              return respond_with_error($!.message, 404, nil, obsolete_client: true)
            end

            netbeans_plugin_blacklist = ['1.1.9']
            vscode_plugin_blacklist = ['1.3.0', '1.3.2']

            if params[:client] == 'netbeans_plugin' && (netbeans_plugin_blacklist.include? params[:client_version]) && !params[:paste].nil?
              authorization_skip!
              return respond_with_error("\nYou need to update your client. You can do that by selecting 'Help' -> 'Check for updates' and then following instructions.", 404, nil, obsolete_client: true)
            end

            if params[:client] == 'vscode_plugin' && (vscode_plugin_blacklist.include? params[:client_version])
              authorization_skip!
              respond_with_error("\nThis version of the TMC extension contains bugs.\nYou need to update your TMC extension.", 404, nil, obsolete_client: true)
            end
          end
        end

        sig { returns(T::Boolean) }
        def should_check_for_client_version?
          params[:format] == 'json' &&
            (params[:client].present? && params[:client_version].present?) &&
            (controller_path.starts_with? 'api') &&
            (controller_name == 'submissions' && action_name == 'create')
        end

        sig { params(client_name: T.untyped, client_version: T.untyped).void }
        def check_client_minimum_version(client_name, client_version)
          begin
            client_version = Version.new(client_version) unless client_version.nil?
          rescue StandardError
            raise "\nInvalid version string: #{client_version}\n"
          end

          valid_clients = SiteSetting.value('valid_clients')
          if valid_clients.is_a?(Enumerable)
            vc = valid_clients.find { |c| c['name'] == client_name }
            raise "\nInvalid TMC client: #{client_name}.\n" if vc.nil?

            if !client_version.nil? && vc['min_version'].present?
              if client_version < Version.new(vc['min_version'])
                raise "\nPlease update the TMC client.\nYour client version #{client_version} for #{client_name} is not supported by the server.\nMinimum version requirement: #{vc['min_version']}."
              end
            else
              nil # without version check
            end
          end
        end
    end
  end
end
