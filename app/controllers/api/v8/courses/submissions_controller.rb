module Api
  module V8
    module Courses
      class SubmissionsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/courses/{course_id}/submissions' do
          operation :get do
            key :description, 'Returns the submissions visible to the user in a json format'
            key :operationId, 'findSubmissionsById'
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'submission'
            ]
            parameter '$ref': '#/parameters/path_course_id'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, 'Submissions in json'
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

        around_action :wrap_transaction

        def index
          unauthorize_guest!
          course = Course.find_by!(id: params[:course_id])
          submissions = Submission.where(course_id: course.id)
          readable = Submission.filter_fields(submissions.select { |sub| sub.readable_by?(current_user) })

          authorize_collection :read, readable
          present(readable)
        end
      end
    end
  end
end
