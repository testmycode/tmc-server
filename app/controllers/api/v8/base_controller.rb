# frozen_string_literal: true

require 'json'

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

      private

        def authenticate_user!
          return @current_user if @current_user
          if doorkeeper_token
            @current_user ||= User.find_by(id: doorkeeper_token.resource_owner_id)
            raise 'Invalid token' unless @current_user
          end
          @current_user ||= user_from_session || Guest.new
        end

        attr_reader :current_user

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
              render json: { error: msg }.merge(extra_json_keys), status: :forbidden if code == 403
              render json: { error: msg }.merge(extra_json_keys), status: :unauthorized if code == 401
              render json: { error: msg }.merge(extra_json_keys), status: code
            end
            format.text { render text: 'ERROR: ' + msg, status: code }
            format.zip { render text: msg, status: code, content_type: 'text/plain' }
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
              return respond_with_error("\nThis version of the TMC extension contains bugs.\nYou need to update your TMC extension.", 404, nil, obsolete_client: true)
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
              return # without version check
            end
          end
        end
    end
  end
end
