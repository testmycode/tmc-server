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

              progress_per_part = course.exercise_group_completion_counts_for_user(user)

              progress = {points_by_part:[]}

              progress_per_part.each do |part|
                progress.points_by_part[part] = {
                  progress: part.progress,
                  n_points: part.awarded + part.late,
                  max_points: part.available_points,
                }
              end

              present progress
            end
          end
        end
      end
    end
  end
end
