# frozen_string_literal: true

module Api
  module V8
    module Application
      # Issues a login access token for a user to a trusted backend, e.g. for a sign-in handoff
      # verified elsewhere. Only allow-listed client_credentials applications holding the
      # issue_user_access_tokens scope may call it.
      class UserAccessTokensController < Api::V8::BaseController
        include Swagger::Blocks

        REQUIRED_SCOPE = 'issue_user_access_tokens'
        TOKEN_LIFETIME = 1.day

        swagger_path '/api/v8/application/user_access_tokens' do
          operation :post do
            key :description, "Issues an access token for the given user, owned by the configured target application. Requires a client_credentials token of an allow-listed application with the #{REQUIRED_SCOPE} scope. Administrators, teachers and assistants are refused. The token cannot change the user's email or password or delete the account. It expires after #{TOKEN_LIFETIME.to_i} seconds."
            key :operationId, 'issueUserAccessToken'
            key :produces, ['application/json']
            key :tags, ['user']
            parameter do
              key :name, :user_id
              key :in, :body
              key :description, "The user's id"
              key :required, true
              schema do
                key :'$ref', :UserAccessTokenInput
              end
            end
            response 200 do
              key :description, 'The issued access token'
              schema do
                key :'$ref', :UserAccessToken
              end
            end
            response 400, '$ref': '#/responses/error'
            response 401, '$ref': '#/responses/error'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
          end
        end

        swagger_schema :UserAccessTokenInput do
          key :required, [:user_id]
          property :user_id, type: :integer, example: 1
        end

        swagger_schema :UserAccessToken do
          key :required, %i[access_token token_type created_at expires_in]
          property :access_token, type: :string
          property :token_type, type: :string, example: 'bearer'
          property :created_at, type: :integer, description: 'Unix timestamp'
          property :expires_in, type: :integer, description: 'Seconds from created_at', example: 86_400
        end

        skip_before_action :authenticate_user!
        skip_authorization_check

        def create
          return respond_unauthorized unless doorkeeper_token&.accessible?
          return respond_forbidden unless authorized_issuer?

          user_id = Integer(params[:user_id].to_s, 10, exception: false)
          return respond_with_error('user_id must be an integer', 400) unless user_id

          user = User.find_by(id: user_id)
          return respond_not_found('User not found') unless user
          return respond_forbidden('Tokens are not issued for administrators, teachers or assistants') if privileged?(user)

          target_application = Doorkeeper::Application.find_by(uid: Rails.configuration.x.user_access_token_target_application_uid)
          return respond_with_error('Target application is not configured', 500) unless target_application

          token = Doorkeeper::AccessToken.create_for(
            application: target_application,
            resource_owner: user,
            scopes: "public #{HANDOFF_TOKEN_SCOPE}",
            expires_in: TOKEN_LIFETIME.to_i
          )
          Rails.logger.info("Issued user access token: issuer application uid=#{doorkeeper_token.application.uid} user_id=#{user.id}")

          render json: {
            access_token: token.plaintext_token,
            token_type: 'bearer',
            created_at: token.created_at.to_i,
            expires_in: token.expires_in
          }
        end

        private
          def privileged?(user)
            user.administrator? || user.teacherships.exists? || user.assistantships.exists?
          end

          def authorized_issuer?
            issuer_uids = Rails.configuration.x.user_access_token_issuer_application_uids
            application = doorkeeper_token.application
            # resource_owner_id is set on user tokens, which never qualify even from an allowed application.
            # The target is a frontend client, so its credentials must not be usable to issue tokens.
            doorkeeper_token.resource_owner_id.nil? &&
              issuer_uids.include?(application&.uid) &&
              application.uid != Rails.configuration.x.user_access_token_target_application_uid &&
              doorkeeper_token.acceptable?([REQUIRED_SCOPE])
          end
      end
    end
  end
end
