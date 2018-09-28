# frozen_string_literal: true

require 'json'

class Api::Beta::BaseController < ApplicationController
  clear_respond_to
  respond_to :json

  #  before_action :doorkeeper_authorize!
  before_action :authenticate_user!

  skip_authorization_check # we use doorkeeper in api, so let's skip cancancan

  rescue_from CanCan::AccessDenied do |e|
    render json: errors_json(e.message), status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: errors_json(e.message), status: :not_found
  end

  def present(hash)
    if !!params[:pretty]
      render json: JSON.pretty_generate(hash)
    else
      render json: hash.to_json
    end
  end

  private

    def authenticate_user!
      if doorkeeper_token
        @current_user = User.find(doorkeeper_token.resource_owner_id)
      end

      return if @current_user

      render json: { errors: ['User is not authenticated!'] }, status: :unauthorized
    end

    attr_reader :current_user

    def errors_json(messages)
      { errors: [*messages] }
    end
end
