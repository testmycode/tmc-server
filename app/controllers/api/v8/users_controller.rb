# frozen_string_literal: true

module Api
  module V8
    class UsersController < Api::V8::BaseController
      include Swagger::Blocks

      swagger_path '/api/v8/users/{user_id}' do
        operation :get do
          key :description, "Returns the user's username, email, and administrator status by user id"
          key :operationId, 'findUsersBasicInfoById'
          key :produces, [
            'application/json'
          ]
          key :tags, [
            'user'
          ]
          parameter '$ref': '#/parameters/path_user_id'
          response 200 do
            key :description, "User's username, email, and administrator status by id as json"
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
          key :description, "Returns the current user's username, email, and administrator status"
          key :operationId, 'findUsersBasicInfo'
          key :produces, [
            'application/json'
          ]
          key :tags, [
            'user'
          ]
          response 200 do
            key :description, "User's username, email, and administrator status as json"
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

      swagger_path '/api/v8/users/{user_id}/set_password_managed_by_courses_mooc_fi' do
        operation :post do
          key :description, 'Sets the boolean password_managed_by_courses_mooc_fi for the user with the given id to true.'
          key :operationId, 'setPasswordManagedByCoursesMoocFi'
          key :produces, ['application/json']
          key :tags, ['user']
          parameter '$ref': '#/parameters/user_id'
          response 403, '$ref': '#/responses/error'
          response 404, '$ref': '#/responses/error'
          response 200 do
            key :description, "status 'ok' and sets the boolean password_managed_by_courses_mooc_fi to true"
            schema do
              key :title, :status
              key :required, [:status]
              property :status, type: :string, example: 'Password managed by courses.mooc.fi set to true and password deleted.'
            end
          end
        end
      end

      skip_authorization_check only: %i[set_password_managed_by_courses_mooc_fi]

      def show
        unauthorize_guest! if current_user.guest?
        user = current_user
        user = User.find_by!(id: params[:id]) unless params[:id] == 'current'
        authorize! :read, user

        data = {
          id: user.id,
          username: user.login,
          email: user.email,
          administrator: user.administrator
        }

        if params[:show_user_fields]
          user_field = {}
          UserField.all.select { |f| f.visible_to?(current_user) }.each do |field|
            value_record = user.field_value_record(field)
            value = value_record.ruby_value
            user_field[field.name] = value
          end
          data[:user_field] = user_field
        end

        if params[:extra_fields]
          extra_fields = {}
          namespace = params[:extra_fields]
          UserAppDatum.where(namespace: namespace, user: user).each do |datum|
            extra_fields[datum.field_name] = datum.value
          end
          data[:extra_fields] = extra_fields
        end
        render json: data
      end

      def create
        authorize! :create, User

        @user = User.new

        @user.login = SecureRandom.uuid

        set_email
        set_password
        set_user_fields
        set_extra_data

        if BannedEmail.banned?(@user.email)
          return render json: {
            success: true,
            message: 'User created.'
          }
        end

        if @user.errors.empty? && @user.save
          # TODO: Whitelist origins
          UserMailer.email_confirmation(@user, params[:origin], params[:language]).deliver_now
          render json: {
            success: true,
            message: 'User created.'
          }
        else
          errors = @user.errors
          errors[:username] = errors.delete(:login) if errors.key?(:login)
          render json: {
            success: false,
            errors: @user.errors
          }
        end
      end

      def update
        unauthorize_guest! if current_user.guest?

        User.transaction do
          @user = current_user
          @user = User.find_by!(id: params[:id]) unless params[:id] == 'current'
          @email_before = @user.email
          authorize! :update, @user
          set_user_fields
          set_extra_data(true)
          update_email
          maybe_update_password
          raise ActiveRecord::Rollback if !@user.errors.empty? || !@user.save
          RecentlyChangedUserDetail.email_changed.create!(old_value: @email_before, new_value: @user.email, username: @user.login, user_id: @user.id) unless @email_before.casecmp(@user.email).zero?
          return render json: {
            message: 'User details updated.'
          }
        end
        render json: {
          errors: @user.errors
        }, status: :bad_request
      end

      def set_password_managed_by_courses_mooc_fi
        only_admins!

        User.transaction do
          user = User.find_by!(id: params[:id])
          user.password_managed_by_courses_mooc_fi = true
          user.password_hash = nil
          user.salt = nil
          user.argon_hash = nil
          raise ActiveRecord::Rollback if !user.errors.empty? || !user.save
          return render json: {
            status: 'Password managed by courses.mooc.fi set to true and password deleted.'
          }
        end
        render json: {
          errors: @user.errors
        }, status: :bad_request
      end

      private
        def set_email
          user_params = params[:user]

          return unless @user.new_record?

          if user_params[:email].blank?
            @user.errors.add(:email, 'needed')
          else
            @user.email = user_params[:email].strip
          end
        end

        def update_email
          user_params = params[:user]
          return unless user_params[:email]
          new_email = user_params[:email].strip
          if new_email.blank?
            @user.errors.add(:email, 'needed')
          elsif @user.email.casecmp(new_email) != 0
            @user.email = new_email
            @user.email_verified = false
            UserMailer.email_confirmation(@user, params[:origin], params[:language]).deliver_now
          end
        end

        def set_password
          user_params = params[:user]
          if user_params[:password].blank?
            @user.errors.add(:password, 'needed')
          elsif user_params[:password].length > 1000
            @user.errors.add(:password, 'cannot be over 1000 characters')
          elsif user_params[:password] != user_params[:password_confirmation]
            @user.errors.add(:password_confirmation, 'did not match')
          else
            @user.password = user_params[:password]
          end
        end

        def maybe_update_password
          if params[:old_password].present? && params[:password].present?
            if !@user.has_password?(params[:old_password])
              @user.errors.add(:old_password, 'incorrect')
            elsif params[:password] != params[:password_repeat]
              @user.errors.add(:password_repeat, 'did not match')
            elsif params[:password].blank?
              @user.errors.add(:password, 'cannot be empty')
            elsif params[:password].length > 1000
              @user.errors.add(:password, 'cannot be over 1000 characters')
            else
              @user.password = params[:password]
            end
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

        def set_extra_data(eager_save = false)
          return unless params['user']
          extra_fields = params['user']['extra_fields']
          return if extra_fields.nil?
          namespace = extra_fields['namespace']
          raise 'Namespace not defined' unless namespace
          extra_fields['data'].each do |key, value|
            datum = @user.user_app_data.find_or_initialize_by(namespace: namespace, field_name: key)
            datum.value = value
            datum.save! if eager_save
          end
        end
    end
  end
end
