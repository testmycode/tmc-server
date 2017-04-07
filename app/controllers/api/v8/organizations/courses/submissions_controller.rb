module Api
  module V8
    module Organizations
      module Courses
        class SubmissionsController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/submissions' do
            operation :get do
              key :description, 'Returns the submissions visible to the user in a json format'
              key :operationId, 'findSubmissions'
              key :produces, [
                'application/json'
              ]
              key :tags, [
                'submission'
              ]
              parameter '$ref': '#/parameters/path_organization_id'
              parameter '$ref': '#/parameters/path_course_name'
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
            course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
            submissions = Submission.where(course_id: course.id)
            readable = Submission.filter_fields!(submissions.select { |sub| sub.readable_by?(current_user) })

            authorize_collection :read, readable
            present(readable)
          end
        end
      end
    end
  end
end
