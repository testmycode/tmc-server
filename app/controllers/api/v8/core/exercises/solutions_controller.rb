# frozen_string_literal: true

module Api
  module V8
    module Core
      module Exercises
        class SolutionsController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/core/exercises/{exercise_id}/solution/download' do
            operation :get do
              key :description, 'Download the solution for an exercise as a zip file'
              key :operationId, 'downloadSolution'
              key :produces, ['application/zip']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_exercise_id'
              response 200 do
                key :description, 'Solution zip file'
                schema do
                  key :type, :file
                end
              end
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
            end
          end

          around_action :wrap_transaction

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
end
