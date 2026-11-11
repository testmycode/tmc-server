# typed: strict
# frozen_string_literal: true

module Api
  module V8
    module Users
      class RequestDeletionController < Api::V8::BaseController
        skip_authorization_check

        sig { void }
        def create
          unauthorize_guest!
          deletion_url = User.courses_mooc_fi_account_deletion_url
          message = deletion_url ? 'Accounts are deleted on courses.mooc.fi.' : 'Please contact support to delete your account.'
          render json: { errors: [message], account_deletion_url: deletion_url }, status: :gone
        end
      end
    end
  end
end
