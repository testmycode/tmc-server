# frozen_string_literal: true

module Api
  module V8
    module Organizations
      module Courses
        module Users
          class PointsController < Api::V8::BaseController
            include Swagger::Blocks

            swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}/users/{user_id}/points' do
              operation :get do
                key :description, "Returns the given user's points from the course in a json format. Course is searched by name"
                key :produces, ['application/json']
                key :tags, ['point']
                parameter '$ref': '#/parameters/path_organization_slug'
                parameter '$ref': '#/parameters/path_course_name'
                parameter '$ref': '#/parameters/path_user_id'
                response 403, '$ref': '#/responses/error'
                response 404, '$ref': '#/responses/error'
                response 200 do
                  key :description, 'Points in json'
                  schema do
                    key :type, :array
                    items do
                      key :'$ref', :AwardedPointWithExerciseId
                    end
                  end
                end
              end
            end

            swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}/users/current/points' do
              operation :get do
                key :description, "Returns the current user's points from the course in a json format. Course is searched by name"
                key :produces, ['application/json']
                key :tags, ['point']
                parameter '$ref': '#/parameters/path_organization_slug'
                parameter '$ref': '#/parameters/path_course_name'
                response 403, '$ref': '#/responses/error'
                response 404, '$ref': '#/responses/error'
                response 200 do
                  key :description, 'Points in json'
                  schema do
                    key :type, :array
                    items do
                      key :'$ref', :AwardedPointWithExerciseId
                    end
                  end
                end
              end
            end

            def index
              course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
              params[:user_id] = current_user.id if params[:user_id] == 'current'
              points = course.awarded_points.includes(:submission).where(user_id: params[:user_id])
              authorize_collection :read, points
              present points.as_json_with_exercise_ids(course.exercises)
            end
          end
        end
      end
    end
  end
end
