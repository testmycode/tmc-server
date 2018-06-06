# frozen_string_literal: true

module Api
  module V8
    module Users
      class RequestDeletionController < Api::V8::BaseController
        skip_authorization_check

        def create
          user = User.find(params[:user_id])
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
