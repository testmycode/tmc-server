# frozen_string_literal: true
module Api
  module V8
    class UserAppDatumController < Api::V8::BaseController
      skip_authorization_check
      def index
        only_admins!

        if params[:after]
          timestamp = Time.zone.parse(params[:after])
          data = UserAppDatum.where('created_at >= ? OR updated_at >= ?', timestamp, timestamp)
          return render json: data
        end

        headers['X-Accel-Buffering'] = 'no'
        headers['Cache-Control'] = 'no-cache'
        headers['Content-Type'] = 'application/json'
        # headers['Transfer-Encoding'] = 'chunked' 
        headers.delete('Content-Length')

        self.response_body = build_json_enumerator(-> { UserAppDatum.all })
        # render json: UserAppDatum.all
      end

      private
        def build_json_enumerator(query)
          first = true
          Enumerator.new do |yielder|
            yielder << '['
            query.call.each do |datum|
              yielder << ',' unless first
              yielder << datum.to_json
              first = false
            end
            yielder << ']'
          end
      end
    end
  end
end
