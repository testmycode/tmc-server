module Api
  module V8
    module Organizations
      module Courses
        class ExercisesController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises' do
            operation :get do
              key :description, 'Returns all exercises of the course as json. Course is searched by name'
              key :operationId, 'findExercisesByName'
              key :produces, ['application/json']
              key :tags, ['exercise']
              parameter '$ref': '#/parameters/path_organization_id'
              parameter '$ref': '#/parameters/path_course_name'
              response 200 do
                key :description, 'Exercises in json'
                schema do
                  key :title, :exercises
                  key :required, [:exercises]
                  property :exercises do
                    key :type, :array
                    items do
                      key :'$ref', :ExerciseWithPoints
                    end
                  end
                end
              end
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
            end
          end

          swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/download' do
            operation :get do
              key :description, 'Download the exercise as a zip file'
              key :operationId, 'downloadExercise'
              key :produces, ['application/zip']
              key :tags, ['exercise']
              parameter '$ref': '#/parameters/path_organization_id'
              parameter '$ref': '#/parameters/path_course_name'
              parameter '$ref': '#/parameters/path_exercise_name'
              response 200 do
                key :description, 'Exercise zip file'
                schema do
                  key :type, :file
                end
              end
              response 404, '$ref': '#/responses/error'
            end
          end

          def index
            unauthorize_guest!
            course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
            exercises = Exercise.includes(:available_points).where(course_id: course.id)

            visible = exercises.select { |ex| ex.visible_to?(current_user) }
            presentable = visible.map do |ex|
              {
                id: ex.id,
                available_points: ex.available_points,
                name: ex.name,
                publish_time: ex.publish_time,
                solution_visible_after: ex.solution_visible_after,
                deadline: ex.deadline_for(current_user),
                disabled: ex.disabled?
              }
            end

            authorize_collection :read, visible
            present(presentable)
          end

          def download
            course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
            exercise = Exercise.find_by!(name: params[:name], course_id: course.id)

            authorize! :download, exercise
            send_file exercise.stub_zip_file_path
          end
        end
      end
    end
  end
end
