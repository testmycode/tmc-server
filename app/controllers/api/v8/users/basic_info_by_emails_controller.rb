# frozen_string_literal: true

module Api
  module V8
    module Users
      class BasicInfoByEmailsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/users/basic_info_by_emails' do
          operation :post do
            key :description, "Find all users' basic infos with the posted json array of emails"
            key :operationId, 'findUsersBasicInfoByEmails'
            parameter do
              key :name, :emails
              key :in, :body
              key :description, 'emails for which to find basic infos'
              key :required, true
              schema do
                key :'$ref', :EmailsInput
              end
            end
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'user'
            ]
            response 200 do
              key :description, "Users' username, email, and administrator status by usernames as json"
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

        swagger_schema :EmailsInput do
          allOf do
            schema do
              property :emails do
                key :type, :array
                items do
                  key :type, :string
                  property :email do
                    key :type, :string
                  end
                end
              end
            end
          end
        end

        skip_authorization_check

        def create
          return respond_forbidden unless current_user.administrator?
          users = params[:emails].map do |email|
            User.find_by('lower(email) = ?', email.downcase)
          end.compact
          user_id_to_extra_fields = nil
          if params[:extra_fields]
            namespace = params[:extra_fields]
            user_id_to_extra_fields = UserAppDatum.where(namespace: namespace, user: users).group_by(&:user_id)
          end

          data = users.map do |u|
            d = {
              id: u.id,
              username: u.login,
              email: u.email,
              administrator: u.administrator
            }
            if user_id_to_extra_fields
              extra_fields = user_id_to_extra_fields[u.id] || []
              d[:extra_fields] = extra_fields.map { |o| [o.field_name, o.value] }.to_h
            end
            if params[:user_fields]
              user_fields = u.user_field_values.map {|o| [o.field_name, o.value]}.to_h
              d[:user_fields] = user_fields
              d[:student_number] = user_fields["organizational_id"]
              d[:first_name] = user_fields["first_name"]
              d[:last_name] = user_fields["last_name"]
            end
            d
          end
          render json: data
        end
      end
    end
  end
end
