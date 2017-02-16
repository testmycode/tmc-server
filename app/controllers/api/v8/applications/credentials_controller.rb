module Api
  module V8
    module Applications
      class CredentialsController < Api::V8::BaseController
        def show
          application = Application.find_by!(name: params[:name])
          present application
        end
      end
    end
  end
end
