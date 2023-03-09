# frozen_string_literal: true

module Api
  module V8
    module Users
      class AssistantshipsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/users/{user_id}/assistantships' do
          operation :get do
            key :description, 'Returns a list of courses where the user is an assistant'
            key :operationId, 'findAssistantshipsByUserId'
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'assistantship',
            ]
            parameter '$ref': '#/parameters/path_user_id'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, "User's assisted courses as a list"
              schema do
                key :title, :assistantships
                key :required, [:assistantships]
                property :assistantships do
                  key :type, :array
                  items do
                    key :'$ref', :CourseBasicInfo
                  end
                end
              end
            end
          end
        end

        swagger_path '/api/v8/users/current/assistantships' do
          operation :get do
            key :description, 'Returns a list of courses where the current user is an assistant'
            key :operationId, 'findAssistantshipsForCurrentUser'
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'assistantship',
            ]
            parameter '$ref': '#/parameters/path_user_id'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, "User's assisted courses as a list"
              schema do
                key :title, :assistantships
                key :required, [:assistantships]
                property :assistantships do
                  key :type, :array
                  items do
                    key :'$ref', :CourseBasicInfo
                  end
                end
              end
            end
          end
        end

        around_action :wrap_transaction

        def index
          unauthorize_guest!

          params[:user_id] = current_user.id if params[:user_id] == 'current'
          user = User.find(params[:user_id])
          authorize! :read, user

          assisted_courses = user.assistantships.pluck(:course_id)
          readable = Course.find(assisted_courses).map do |c|
            {
              'course_id': c.id,
              'name': c.name,
              'title': c.title,
              'organization_id': c.organization_id,
            }
          end

          authorize! :read, readable
          present(readable)
        end
      end
    end
  end
end
