# frozen_string_literal: true

module Api
    module V8
      module Core
        module Exercises
          class DetailsController < Api::V8::BaseController
            include Swagger::Blocks

            swagger_path '/api/v8/core/exercises/details' do
              operation :get do
                key :description, 'Fetch multiple exercise details as query parameters.'
                key :operationId, 'getExerciseDetailsWithIds'
                key :produces, ['application/json']
                key :tags, ['core']
                parameter do
                  key :in, 'query'
                  key :name, 'ids'
                  schema do
                    key :type, :array
                    items do
                      key :type, :integer
                    end
                  end
                  key :type, :array
                  key :description, 'Exercise Ids'
                end
                response 200 do
                  key :description, 'Exercises in json'
                  schema do
                    key :title, :exercises
                    key :required, [:exercises]
                    property :exercises do
                      key :type, :array
                      items do
                        key :'$ref', :CoreExerciseQueryDetails
                      end
                    end
                  end
                end
                response 403, '$ref': '#/responses/error'
                response 404, '$ref': '#/responses/error'
              end
            end

            skip_authorization_check

            def show
              exercise_ids = params[:ids]
              return respond_not_found('Query param ids is empty. Example: ?ids=1,2,3') if !exercise_ids.present? || exercise_ids.empty?

              exercises = Exercise.where(id: exercise_ids.split(",")).includes(:course)
              authorize! :read, exercises
              data = exercises.map do |exercise|
                {
                  id: exercise.id,
                  checksum: exercise.checksum,
                  course_name: exercise.course.name,
                  exercise_name: exercise.name,
                } 
              end
              present exercises: data
            end
          end
        end
      end
    end
  end
  