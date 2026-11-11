# typed: strict
# frozen_string_literal: true

module Api
  module V8
    module Users
      class RequestDeletionController < Api::V8::BaseController
        skip_authorization_check

        sig { void }
        def create
          render json: {
            errors: ['Accounts are deleted on courses.mooc.fi.'],
            account_deletion_url: current_user.courses_mooc_fi_account_deletion_url
          }, status: :gone
        end
      end
    end
  end
end
