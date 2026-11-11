# typed: strict
# frozen_string_literal: true

module Api
  module V8
    module Users
      class RecentlyChangedUserDetailsController < Api::V8::BaseController
        skip_authorization_check

        sig { void }
        def index
          return respond_forbidden unless current_user.administrator?
          RecentlyChangedUserDetail.deleted.where(created_at: ...(DateTime.now - 1.week)).update(:all, email: nil)
          RecentlyChangedUserDetail.email_changed.where(created_at: ...(DateTime.now - 1.month)).delete_all
          render json: { changes: RecentlyChangedUserDetail.all }
        end
      end
    end
  end
end
