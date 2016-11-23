module Api
  module V8
    module Organizations
      module Courses
        module Exercises
          module Users
            class PointsController < Api::V8::BaseController
              include Swagger::Blocks

              swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/users/current/points' do
                operation :get do
                  key :description, 'Returns all the awarded points of an excercise for current user'
                  key :operationId, 'findCurrentUsersAwardedPointsByCourseNameAndExerciseName'
                  key :produces, ['application/json']
                  key :tags, ['point']
                  parameter '$ref': '#/parameters/path_organization_id'
                  parameter '$ref': '#/parameters/path_course_name'
                  parameter '$ref': '#/parameters/path_exercise_name'
                  response 200 do
                    key :description, 'Awarded points in json'
                    schema do
                      key :title, :points
                      key :required, [:points]
                      property :points do
                        key :type, :array
                        items do
                          key :'$ref', :AvailablePoint
                        end
                      end
                    end
                  end
                  response 403, '$ref': '#/responses/error'
                  response 404, '$ref': '#/responses/error'
                end
              end

              swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/users/{user_id}/points' do
                operation :get do
                  key :description, 'Returns all the awarded points of an excercise for the specified user'
                  key :operationId, 'findUsersAwardedPointsByCourseNameAndExerciseName'
                  key :produces, ['application/json']
                  key :tags, ['point']
                  parameter '$ref': '#/parameters/path_organization_id'
                  parameter '$ref': '#/parameters/path_course_name'
                  parameter '$ref': '#/parameters/path_exercise_name'
                  parameter '$ref': '#/parameters/path_user_id'
                  response 200 do
                    key :description, 'Awarded points in json'
                    schema do
                      key :title, :points
                      key :required, [:points]
                      property :points do
                        key :type, :array
                        items do
                          key :'$ref', :AvailablePoint
                        end
                      end
                    end
                  end
                  response 403, '$ref': '#/responses/error'
                  response 404, '$ref': '#/responses/error'
                end
              end

              def index
                unauthorize_guest!
                course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
                params[:user_id] = current_user.id if params[:user_id] == 'current'

                points = course.awarded_points.includes(:submission)
                             .where(submissions: {exercise_name: params[:exercise_name]},
                                    course_id: course.id,
                                    user_id: params[:user_id])

                authorize! :read, points
                present(points.as_json_with_exercise_ids(course.exercises))
              end
            end
          end
        end
      end
    end
  end
end
