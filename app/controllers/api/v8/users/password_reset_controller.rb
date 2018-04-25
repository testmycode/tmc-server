# frozen_string_literal: true

module Api
  module V8
    module Users
      class PasswordResetController < Api::V8::BaseController
        skip_authorization_check

        def create
          @email = params['email'].to_s.strip
          if @email.empty?
            return render json: {
              success: false,
              errors: 'No email address provided'
            }
          end

          user = User.find_by_email(@email)
          unless user
            return render json: {
              success: false,
              errors: 'No such email address registered'
            }
          end

          key = ActionToken.generate_password_reset_key_for(user)
          # TODO: Whitelist origins
          PasswordResetKeyMailer.reset_link_email(user, key, params['origin']).deliver
          render json: {
            success: true
          }
        end

      end
    end
  end
end
