require 'json'

module Api
  module V8
    class BaseController < ApplicationController
      clear_respond_to
      respond_to :json

      #  before_action :doorkeeper_authorize!
      before_action :authenticate_user!

      rescue_from CanCan::AccessDenied do |e|
        render json: errors_json(e.message), status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: errors_json(e.message), status: :not_found
      end

      def present(hash)
        if params[:pretty]
          render json: JSON.pretty_generate(hash)
        else
          render json: hash.to_json
        end
      end

      private

      def authenticate_user!
        return @current_user if @current_user
        if doorkeeper_token
          @current_user ||= User.find_by_id(doorkeeper_token.resource_owner_id)
          fail 'Invalid token' unless @current_user
        end
        @current_user ||= user_from_session || Guest.new
      end

      attr_reader :current_user

      def errors_json(messages)
        { errors: [*messages] }
      end
    end
  end
end
