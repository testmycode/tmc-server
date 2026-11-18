# typed: strict
# frozen_string_literal: true

module Api
  module V8
    module Users
      class PasswordResetController < Api::V8::BaseController
        skip_authorization_check

        sig { void }
        def create
          email = params['email'].to_s.strip
          if email.empty?
            return render json: {
              success: false,
              errors: 'No email address provided'
            }
          end

          user = User.find_by('lower(email) = ?', email.downcase)
          unless user
            return render json: {
              success: false,
              errors: 'No such email address registered'
            }, status: :not_found
          end

          # Mail is sent only by courses.mooc.fi; the response is kept for existing clients.
          render json: {
            success: true
          }
        end
      end
    end
  end
end
