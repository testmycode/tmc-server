# typed: strict
# frozen_string_literal: true

module Api
  module V8
    module Users
      class TeachershipsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/users/{user_id}/teacherships' do
          operation :get do
            key :description, 'Returns a list of organizations where the user is a teacher'
            key :operationId, 'findTeachershipsByUserId'
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'teachership',
            ]
            parameter '$ref': '#/parameters/path_user_id'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, "User's taught organizations as a list"
              schema do
                key :title, :teacherships
                key :required, [:teacherships]
                property :teacherships do
                  key :type, :array
                  items do
                    key :'$ref', :Organization
                  end
                end
              end
            end
          end
        end

        swagger_path '/api/v8/users/current/teacherships' do
          operation :get do
            key :description, 'Returns a list of organizations where the current user is a teacher'
            key :operationId, 'findTeachershipsForCurrentUser'
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'teachership',
            ]
            parameter '$ref': '#/parameters/path_user_id'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, "User's taught organizations as a list"
              schema do
                key :title, :teacherships
                key :required, [:teacherships]
                property :teacherships do
                  key :type, :array
                  items do
                    key :'$ref', :Organization
                  end
                end
              end
            end
          end
        end

        around_action :wrap_transaction

        sig { void }
        def index
          unauthorize_guest!

          params[:user_id] = current_user.id if params[:user_id] == 'current'
          user = User.find(params[:user_id])
          authorize! :read, user

          taught_organizations = T.let(user.teacherships.pluck(:organization_id), T::Array[Integer])
          readable = Organization.find(taught_organizations).map { |o| o.org_as_json.merge(organization_id: o.id) }

          authorize! :read, readable
          present(readable)
        end
      end
    end
  end
end
