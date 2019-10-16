# frozen_string_literal: true

module Api
  module V8
    class UserFieldValueController < Api::V8::BaseController

      skip_authorization_check
      def index
        only_admins!

        if params[:after]
          timestamp = Time.zone.parse(params[:after])
          data = UserFieldValue.order(:updated_at).where("created_at >= ? OR updated_at >= ?", timestamp, timestamp)
          return render json: data
        end

        render json: UserFieldValue.all
      end
    end
  end
end
