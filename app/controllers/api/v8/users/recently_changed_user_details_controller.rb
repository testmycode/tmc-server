# frozen_string_literal: true

module Api
  module V8
    module Users
      class RecentlyChangedUserDetailsController < Api::V8::BaseController
        skip_authorization_check

        def index
          return respond_forbidden unless current_user.administrator?
          render json: { changes: RecentlyChangedUserDetail.all }
        end
      end
    end
  end
end
