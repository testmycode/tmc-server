module Api
  module V8
    module Exercises
      class SolutionsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/exercises/{exercise_id}/solution/download' do
          operation :get do
            key :description, 'Download the solution for an exercise as a zip file'
            key :operationId, 'downloadSolution'
            key :produces, ['application/zip']
            key :tags, ['exercise']
            parameter '$ref': '#/parameters/path_exercise_id'
            response 200 do
              key :description, 'Solution zip file'
              schema do
                key :type, :file
              end
            end
            response 404, '$ref': '#/responses/error'
          end
        end

        def download
          unauthorize_guest!
          exercise = Exercise.find_by!(id: params[:exercise_id])

          authorize! :read, exercise.solution
          send_file exercise.solution_zip_file_path
        end
      end
    end
  end
end