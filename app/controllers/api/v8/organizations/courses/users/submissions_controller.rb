module Api
  module V8
    module Organizations
      module Courses
        module Users
          class SubmissionsController < Api::V8::BaseController
            include Swagger::Blocks

            swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/users/{user_id}/submissions' do
              operation :get do
                key :description, 'Returns the submissions visible to the user in a json format'
                key :operationId, 'findUsersSubmissionsByCourseName'
                key :produces, [
                  'application/json'
                ]
                key :tags, [
                  'submission'
                ]
                parameter '$ref': '#/parameters/path_organization_id'
                parameter '$ref': '#/parameters/path_course_name'
                parameter '$ref': '#/parameters/path_user_id'
                response 403, '$ref': '#/responses/error'
                response 404, '$ref': '#/responses/error'
                response 200 do
                  key :description, 'User\'s submissions in json'
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

            swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/users/current/submissions' do
              operation :get do
                key :description, 'Returns the user\'s own submissions in a json format'
                key :operationId, 'findUsersOwnSubmissionsByCourseName'
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
                  key :description, 'User\'s own submissions in json'
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
              params[:user_id] = current_user.id if params[:user_id] == 'current'
              submissions = Submission.where(course_id: course.id, user_id: params[:user_id])
              readable = Submission.filter_fields!(submissions.select { |sub| sub.readable_by?(current_user) })

              authorize_collection :read, readable
              present(readable)
            end
          end
        end
      end
    end
  end
end
