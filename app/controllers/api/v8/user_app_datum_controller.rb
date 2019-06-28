# frozen_string_literal: true

module Api
  module V8
    class UserAppDatumController < Api::V8::BaseController

      skip_authorization_check
      def index
        only_admins!

        render json: UserAppDatum.all.to_json
      end
    end
  end
end
