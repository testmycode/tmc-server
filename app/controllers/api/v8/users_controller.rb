# frozen_string_literal: true

module Api
  module V8
    class UsersController < Api::V8::BaseController
      include Swagger::Blocks

      swagger_path '/api/v8/users/{user_id}' do
        operation :get do
          key :description, 'Returns the user\'s username, email, and administrator status by user id'
          key :operationId, 'findUsersBasicInfoById'
          key :produces, [
            'application/json'
          ]
          key :tags, [
            'user'
          ]
          parameter '$ref': '#/parameters/path_user_id'
          response 200 do
            key :description, 'User\'s username, email, and administrator status by id as json'
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

      swagger_path '/api/v8/users/current' do
        operation :get do
          key :description, 'Returns the current user\'s username, email, and administrator status'
          key :operationId, 'findUsersBasicInfo'
          key :produces, [
            'application/json'
          ]
          key :tags, [
            'user'
          ]
          response 200 do
            key :description, 'User\'s username, email, and administrator status as json'
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

      def show
        unauthorize_guest! if current_user.guest?
        user = current_user
        user = User.find_by!(id: params[:id]) unless params[:id] == 'current'
        authorize! :read, user

        present(
          id: user.id,
          username: user.login,
          email: user.email,
          administrator: user.administrator
        )
      end

      def create
        authorize! :create, User

        @user = User.new

        @user.login = params[:user][:username].to_s.strip

        set_email
        set_password
        set_user_fields
        set_extra_data

        if @user.errors.empty? && @user.save
          # TODO: Whitelist origins
          UserMailer.email_confirmation(@user, params[:origin]).deliver_now
          render json: {
            success: true,
            message: 'User created.'
          }
        else
          errors = @user.errors
          errors[:username] = errors.delete(:login) if errors.has_key?(:login)
          render json: {
            success: false,
            errors: @user.errors
          }
        end
      end

      private

      def set_email
        user_params = params[:user]

        return if !@user.new_record?

        if user_params[:email].blank?
          @user.errors.add(:email, 'needed')
        else
          @user.email = user_params[:email].strip
        end
      end

      def set_password
        user_params = params[:user]
        if user_params[:password].blank?
          @user.errors.add(:password, 'needed')
        elsif user_params[:password] != user_params[:password_confirmation]
          @user.errors.add(:password_confirmation, 'did not match')
        else
          @user.password = user_params[:password]
        end
      end

      def set_user_fields
        return if params[:user_field].nil?
        changes = {}
        UserField.all.select { |f| f.visible_to?(current_user) }.each do |field|
          value_record = @user.field_value_record(field)
          old_value = value_record.ruby_value
          value_record.set_from_form(params[:user_field][field.name])
          new_value = value_record.ruby_value
          changes[field.name] = { from: old_value, to: new_value } unless new_value == old_value
        end
        changes
      end

      def set_extra_data
        extra_fields = params['user']['extra_fields']
        return if extra_fields.nil?
        namespace = extra_fields['namespace']
        raise "Namespace not defined" unless namespace
        extra_fields['data'].each do |key, value|
          @user.user_app_data.new(namespace: namespace, field_name: key, value: value)
        end
      end
    end
  end
end
