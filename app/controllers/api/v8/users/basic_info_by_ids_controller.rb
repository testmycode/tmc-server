# frozen_string_literal: true

module Api
  module V8
    module Users
      class BasicInfoByIdsController < Api::V8::BaseController
        skip_authorization_check

        def create
          return respond_forbidden unless current_user.administrator?
          users = if params[:extra_fields]
            User.eager_load(:user_field_values).where(id: params[:ids])
          else
            User.where(id: params[:ids])
          end
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
              user_fields = u.user_field_values.map { |o| [o.field_name, o.value] }.to_h
              d[:user_fields] = user_fields
              d[:student_number] = user_fields['organizational_id']
              d[:first_name] = user_fields['first_name']
              d[:last_name] = user_fields['last_name']
            end
            d
          end
          render json: data
        end
      end
    end
  end
end
