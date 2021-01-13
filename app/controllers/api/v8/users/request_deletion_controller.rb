# frozen_string_literal: true

module Api
  module V8
    module Users
      class RequestDeletionController < Api::V8::BaseController
        skip_authorization_check

        def create
          user = current_user
          user = User.find_by!(id: params[:user_id]) unless params[:user_id] == 'current'
          authorize! :destroy, user
          UserMailer.destroy_confirmation(user).deliver_now
          render json: {
            message: 'Verification email sent'
          }
        end
      end
    end
  end
end
