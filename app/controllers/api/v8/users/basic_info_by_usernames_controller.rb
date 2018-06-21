# frozen_string_literal: true

module Api
  module V8
    module Users
      class BasicInfoByUsernamesController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/users/basic_info_by_usernames' do
          operation :post do
            key :description, 'Find all users\' basic infos with the posted json array of usernames'
            key :operationId, 'findUsersBasicInfoByUsernames'
            parameter do
              key :name, :usernames
              key :in, :body
              key :description, 'usernames for which to find basic infos'
              key :required, true
              schema do
                key :'$ref', :UsernamesInput
              end
            end
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'user'
            ]
            response 200 do
              key :description, 'Users\' username, email, and administrator status by usernames as json'
              schema do
                key :title, :user
                key :required, [:user]
                property :user do
                  key :'$ref', :UsersBasicInfo
                end
              end
            end
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
          end
        end

        swagger_schema :UsernamesInput do
          allOf do
            schema do
              property :usernames do
                key :type, :array
                items do
                  key :type, :string
                  property :username do
                    key :type, :string
                  end
                end
              end
            end
          end
        end


        skip_authorization_check

        def create
          respond_access_denied unless current_user.administrator?
          users = params[:usernames]

          data = User.where(login: users).map do |u|
            {
              id: u.id,
              username: u.login,
              email: u.email,
              administrator: u.administrator
            }
          end
          render json: data
        end
      end
    end
  end
end