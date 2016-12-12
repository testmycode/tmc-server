module Api
  module V8
    module Core
      module Organizations
        module Courses
          class UnlocksController < Api::V8::BaseController
            include Swagger::Blocks

            swagger_path '/api/v8/core/org/{organization_id}/courses/{course_id}/unlock' do
              operation :post do
                key :description, 'Unlocks the courses exercises'
                key :operationId, 'unlockCoursesExercises'
                key :produces, ['application/json']
                key :tags, %w(unlock exercise)
                parameter '$ref': '#/parameters/path_organization_id'
                parameter '$ref': '#/parameters/path_course_id'
                response 200 do
                  key :description, 'status \'ok\' and unlocks exercises'
                  schema do
                    key :title, :status
                    key :required, [:status]
                    property :status, type: :string, example: 'ok'
                  end
                end
                response 403, '$ref': '#/responses/error'
                response 404, '$ref': '#/responses/error'
              end
            end

            around_action :wrap_transaction

            def create
              unauthorize_guest!
              course = Course.find(params[:course_id])
              authorize! :read, course
              exercises = course.unlockable_exercises_for(current_user)

              Unlock.unlock_exercises(exercises, current_user)

              present(status: 'ok')
            end
          end
        end
      end
    end
  end
end
