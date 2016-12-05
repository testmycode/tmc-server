module Api
  module V8
    module Core
      class ExercisesController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/core/exercises/{exercise_id}/download' do
          operation :get do
            key :description, 'Download the exercise as a zip file'
            key :operationId, 'downloadExercise'
            key :produces, ['application/zip']
            key :tags, ['core']
            parameter '$ref': '#/parameters/path_exercise_id'
            response 200 do
              key :description, 'Exercise zip file'
              schema do
                key :type, :file
              end
            end
            response 404, '$ref': '#/responses/error'
          end
        end

        def download
          exercise = Exercise.find_by!(id: params[:id])

          authorize! :download, exercise
          send_file exercise.stub_zip_file_path
        end
      end
    end
  end
end
