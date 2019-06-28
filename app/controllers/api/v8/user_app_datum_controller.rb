# frozen_string_literal: true

module Api
  module V8
    class UserAppDatumController < Api::V8::BaseController

      def index
        only_admins!
        skip_authorization_check
        render json: UserAppDatum.all.to_json
      end
    end
  end
end
