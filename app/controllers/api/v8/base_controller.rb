# frozen_string_literal: true

require 'json'
require 'version'

module Api
  module V8
    class BaseController < ApplicationController
      clear_respond_to
      respond_to :json

      #  before_action :doorkeeper_authorize!
      before_action :authenticate_user!
      before_action :check_client_version_api_v8
      skip_before_action :verify_authenticity_token

      rescue_from CanCan::AccessDenied do |e|
        if current_user.guest?
          respond_unauthorized(e.message)
        else
          respond_forbidden(e.message)
        end
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: errors_json(e.message), status: :not_found
      end

      def present(hash)
        if params[:pretty]
          render json: JSON.pretty_generate(hash)
        else
          render json: hash.to_json
        end
      end

      # The exact UUID format the User model enforces on courses_mooc_fi_user_id (see
      # app/models/user.rb). Duplicated here so the introspected subject is shape-checked before
      # any lookup or the update_column backfill, which bypasses that load-bearing model validation.
      COURSES_MOOC_FI_USER_ID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

      private
        def authenticate_user!
          return @current_user if @current_user
          if doorkeeper_token
            @current_user ||= User.find_by(id: doorkeeper_token.resource_owner_id)
            raise 'Invalid token' unless @current_user
          elsif Rails.configuration.x.accept_courses_mooc_fi_tokens && (bearer = bearer_token).present?
            @current_user ||= user_from_courses_mooc_fi_token(bearer)
          end
          @current_user ||= user_from_session || Guest.new
        end

        attr_reader :current_user

        # Additive, feature-flagged auth path (Rails.configuration.x.accept_courses_mooc_fi_tokens,
        # default off). Only reached when there is no native Doorkeeper token. Treats the bearer as
        # a courses.mooc.fi (secret-project-331) OAuth token, validates it via RFC 7662
        # introspection, and maps it to a local user. Fails closed to nil (caller resolves Guest)
        # on any problem; never raises.
        def user_from_courses_mooc_fi_token(token)
          result = CoursesMoocFiTokenIntrospector.introspect(token)
          return nil unless result

          unless result.scope?('exercise-services')
            Rails.logger.warn('courses.mooc.fi token rejected: missing exercise-services scope')
            return nil
          end

          # The subject is about to be used as courses_mooc_fi_user_id, both for the find_by below
          # and (on a cache miss) for the update_column backfill, which bypasses the model's
          # load-bearing UUID-format validation. Shape-check it once here so a malformed subject can
          # neither be looked up nor persisted. Fail closed on mismatch.
          unless COURSES_MOOC_FI_USER_ID_FORMAT.match?(result.sub)
            Rails.logger.warn('courses.mooc.fi token rejected: subject is not a valid UUID')
            return nil
          end

          user = User.find_by(courses_mooc_fi_user_id: result.sub)
          user ||= backfill_from_upstream_id(result)
          return nil unless user

          # Decision 5 (widened 2026-07-23): introspected tokens must never resolve to an elevated
          # user. Originally admins-only; now also blocks anyone holding any teachership or
          # assistantship, because those grant real CanCan abilities (manage exercises/deadlines,
          # read others' submissions). Elevated users keep using native tmc tokens; fail closed to
          # Guest here.
          reason = elevated_user_reason(user)
          if reason
            Rails.logger.warn("courses.mooc.fi token resolved to #{reason} user #{user.id}; refusing introspected auth (elevated users must use native tmc tokens)")
            return nil
          end

          user
        rescue => e
          Rails.logger.warn("courses.mooc.fi token authentication error: #{e.class}: #{e.message}")
          nil
        end

        # nil when the user holds no elevated role; otherwise a short reason naming the highest
        # concern (administrator > teacher > assistant), used only for the warn log. Uses efficient
        # existence checks rather than loading and iterating every organization/course.
        def elevated_user_reason(user)
          return 'administrator' if user.administrator?
          return 'teacher' if Teachership.exists?(user_id: user.id)
          return 'assistant' if Assistantship.exists?(user_id: user.id)
          nil
        end

        # No user is mapped to this token's subject yet, but the introspection response carries the
        # TMC integer id (upstream_id). Look the user up by it and backfill the UUID so later
        # requests resolve directly. Guarded against the unique-index race and against clobbering a
        # user already bound to a different subject.
        def backfill_from_upstream_id(result)
          upstream_id = result.upstream_id
          return nil if upstream_id.blank?

          user = User.find_by(id: upstream_id)
          return nil unless user

          if user.courses_mooc_fi_user_id.blank?
            begin
              user.update_column(:courses_mooc_fi_user_id, result.sub)
            rescue ActiveRecord::RecordNotUnique
              # Another request backfilled the same subject first. Trust the authoritative mapping.
              user = User.find_by(courses_mooc_fi_user_id: result.sub)
            end
          elsif user.courses_mooc_fi_user_id != result.sub
            # upstream_id points at a user already bound to a different subject. Do not override.
            Rails.logger.warn("courses.mooc.fi upstream_id #{upstream_id} maps to user #{user.id} already bound to a different courses_mooc_fi_user_id; refusing")
            return nil
          end

          user
        end

        def bearer_token
          auth = request.authorization
          return nil unless auth
          match = auth.match(/\ABearer[ ]+(.+)\z/i)
          match && match[1]
        end

        def errors_json(messages)
          { errors: [*messages] }
        end

        def respond_not_found(msg = 'Not Found')
          respond_with_error(msg, 404)
        end

        def respond_forbidden(msg = 'Forbidden')
          respond_with_error(msg, 403)
        end

        def respond_unauthorized(msg = 'Authentication required')
          respond_with_error(msg, 401)
        end

        def respond_with_error(msg, code = 500, exception = nil, extra_json_keys = {})
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

        def should_check_for_client_version?
          params[:format] == 'json' &&
            (params[:client].present? && params[:client_version].present?) &&
            (controller_path.starts_with? 'api') &&
            (controller_name == 'submissions' && action_name == 'create')
        end

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
