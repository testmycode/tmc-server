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
          puts "current_user", @current_user
          puts "token", bearer_token

          return @current_user if @current_user

          if doorkeeper_token
            @current_user ||= User.find_by(id: doorkeeper_token.resource_owner_id)
            raise 'Invalid token' unless @current_user
          else
            moocfi_user = validate_moocfi_user
            puts "moocfi_user", moocfi_user
            raise 'Invalid token' unless moocfi_user

            @current_user ||= User.find_by(id: moocfi_user['upstream_id']) if moocfi_user['upstream_id'] > 0 
            @current_user ||= create_user_from_moocfi(moocfi_user) if not moocfi_user['upstream_id'] or moocfi_user['upstream_id'] < 0
            puts "current_user after find or create", @current_user
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

        def bearer_token
          pattern = /^Bearer /
          authorization = request.authorization
          authorization.gsub(pattern, '') if authorization && authorization.match(pattern)
        end

        def validate_moocfi_user
          uri = URI('http://localhost:4000/auth/validate')
          req = Net::HTTP::Get.new(uri)
          req["Authorization"] = request.authorization

          mooc_response = Net::HTTP.start(uri.hostname, uri.port) {|http|
            res = http.request(req)
            JSON.parse(res.body)
          }
          user = mooc_response["user"]
          puts user
          user 
          # @current_user ||= user
          # @current_user ||= User.new({
          #   id: user.id,
          #   login: user.username,
          #   email: user.email
          # })

          # .find_by(id: mooc_response["user"]["upstream_id"])
        end

        def create_user_from_moocfi(moocfi_user)
          puts "creating new user from", moocfi_user
          user = User.new
          user.login = SecureRandom.uuid
          user.email = moocfi_user['email']
          user.password = SecureRandom.base64(12)
          user.administrator = moocfi_user['administrator'] || false

          user.save!

          first_name = UserFieldValue.new(field_name: 'first_name', user_id: user.id, value: moocfi_user['first_name'])
          last_name = UserFieldValue.new(field_name: 'last_name', user_id: user.id, value: moocfi_user['last_name'])
          # first_name = user.user_field_values.new(field_name: 'first_name', value: moocfi_user['first_name'])
          # last_name = user.user_field_values.new(field_name: 'last_name', value: moocfi_user['last_name'])

          first_name.save!
          last_name.save!

          puts "new user?", user.to_json

          update_moocfi_user(user)

          user
        end 
        
        def update_moocfi_user(user)
          uri = URI('http://localhost:4000/api/user/update-from-tmc')
          req = Net::HTTP::Post.new(uri, initheader = { 'Content-Type' => 'application/json' })
          req["Authorization"] = request.authorization
          req.body = { upstream_id: user['id'] }.to_json

          mooc_response = Net::HTTP.start(uri.hostname, uri.port) {|http|
            http.request(req)
          }
          puts mooc_response.code
          raise "Error updating MOOC.fi user" if mooc_response.code.to_i >= 400

        end
    end
  end
end
