# frozen_string_literal: true

module Api
  module V8
    module Organizations
      module Courses
        module Users
          class ProgressController < Api::V8::BaseController
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
              unauthorize_guest!
              course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
              params[:user_id] = current_user.id if params[:user_id] == 'current'
              user = User.find(params[:user_id])
              authorize! :read, user

              progress_per_group = course.exercise_group_completion_counts_for_user(user)

              by_group = progress_per_group.map do |group, info|
                {
                  group: group,
                  progress: info.progress,
                  n_points: info.awarded + info.late,
                  max_points: info.available_points,
                }
              end

              render json: {
                points_by_group: by_group
              }
            end
          end
        end
      end
    end
  end
end
