module Api
  module V8
    module Organizations
      module Courses
        class PointsController < Api::V8::BaseController

          include Swagger::Blocks

          swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/points' do
            operation :get do
              key :description, "Returns the course's points in a json format. Course is searched by name"
              key :produces, ['application/json']
              key :tags, ['point']
              parameter '$ref': '#/parameters/path_organization_id'
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
            points = course.awarded_points.includes(:submission)
            authorize_collection :read, points
            present points.as_json_with_exercise_ids(course.exercises)
          end
        end
      end
    end
  end
end
