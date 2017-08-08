module Api
  module V8
    module Application
      class CredentialsController < Api::V8::BaseController
        skip_authorization_check
        def index
          valid_clients = SiteSetting.value('valid_clients')
                                     .map { |o| o['name'] }
          return unless valid_clients.is_a?(Enumerable)
          return render json: 'Client not supported!', status: :forbidden unless valid_clients.include?(params[:application_name])
          app = Doorkeeper::Application.create_with(redirect_uri: 'urn:ietf:wg:oauth:2.0:oob').find_or_create_by!(name: params[:application_name])
          present(application_id: app.uid, secret: app.secret)
        end
      end
    end
  end
end
