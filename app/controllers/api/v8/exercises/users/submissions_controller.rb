# frozen_string_literal: true

module Api
  module V8
    module Exercises
      module Users
        class SubmissionsController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path 'api/v8/exercises/{exercise_id}/users/{user_id}/submissions' do
            operation :get do
              key :description, 'Returns the submissions visible to the user in a json format'
              key :operationId, 'findUsersSubmissionsForExerciseById'
              key :produces, ['application/json']
              key :tags, ['exercise', 'submission']
              parameter '$ref': '#/parameters/path_exercise_id'
              parameter '$ref': '#/parameters/path_user_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, "User's submissions for exercise in json"
                schema do
                  key :title, :submissions
                  key :required, [:submissions]
                  property :submissions do
                    key :type, :array
                    items do
                      key :'$ref', :Submission
                    end
                  end
                end
              end
            end
          end

          swagger_path 'api/v8/exercises/{exercise_id}/users/current/submissions' do
            operation :get do
              key :description, "Returns the current user's submissions for the exercise in a json format. The exercise is searched by id."
              key :operationId, 'findUsersOwnSubmissionsForExerciseById'
              key :produces, ['application/json']
              key :tags, ['exercise', 'submission']
              parameter '$ref': '#/parameters/path_exercise_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, "User's own submissions for exercise in json"
                schema do
                  key :title, :submissions
                  key :required, [:submissions]
                  property :submissions do
                    key :type, :array
                    items do
                      key :'$ref', :Submission
                    end
                  end
                end
              end
            end
          end

          def index
            unauthorize_guest!
            exercise = Exercise.find_by!(id: params[:exercise_id])
            params[:user_id] = current_user.id if params[:user_id] == 'current'
            submissions = Submission.where(course_id: exercise.course_id, exercise_name: exercise.name, user_id: params[:user_id])
            readable = Submission.filter_fields!(submissions.select { |sub| sub.readable_by?(current_user) })

            authorize! :read, readable
            present(readable)
          end
        end
      end
    end
  end
end
