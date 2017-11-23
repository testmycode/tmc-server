module Api
  module V8
    module Organizations
      module Courses
        module Exercises
          class PointsController < Api::V8::BaseController
            include Swagger::Blocks

            swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}/exercises/{exercise_name}/points' do
              operation :get do
                key :description, 'Returns all the awarded points of an excercise for all users'
                key :operationId, 'findAllAwardedPointsByCourseNameAndExerciseName'
                key :produces, ['application/json']
                key :tags, ['point']
                parameter '$ref': '#/parameters/path_organization_slug'
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

            def index
              unauthorize_guest!
              course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")

              points = course.awarded_points.includes(:submission)
                       .where(submissions: { exercise_name: params[:exercise_name] },
                              course_id: course.id)

              authorize! :read, points
              present(points.as_json_with_exercise_ids(course.exercises))
            end
          end
        end
      end
    end
  end
end
