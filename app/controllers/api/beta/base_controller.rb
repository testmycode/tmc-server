# typed: strict
# frozen_string_literal: true

require 'json'

class Api::Beta::BaseController < ApplicationController
  extend T::Sig
  clear_respond_to
  respond_to :json

  #  before_action :doorkeeper_authorize!
  before_action :authenticate_user!

  skip_authorization_check # we use doorkeeper in api, so let's skip cancancan

  rescue_from CanCan::AccessDenied do |e|
    T.bind(self, Api::Beta::BaseController)
    render json: errors_json(e.message), status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    T.bind(self, Api::Beta::BaseController)
    render json: errors_json(e.message), status: :not_found
  end

  sig { params(hash: T.untyped).void }
  def present(hash)
    if !!params[:pretty]
      render json: JSON.pretty_generate(hash)
    else
      render json: hash.to_json
    end
  end

  private
    sig { void }
    def authenticate_user!
      if (token = doorkeeper_token)
        @current_user = T.let(User.find_by(id: token.resource_owner_id), T.nilable(User))
      end

      return if @current_user

      render json: { errors: ['User is not authenticated!'] }, status: :unauthorized
    end

    # Before authenticate_user! has run (ApplicationController's own before_actions), this is a Guest.
    sig { returns(User) }
    def current_user
      @current_user || Guest.new
    end

    sig { params(messages: T.any(String, T::Array[String])).returns(T::Hash[Symbol, T::Array[String]]) }
    def errors_json(messages)
      { errors: [*messages] }
    end
end
