module Api
  module V8
    module Courses
      module Submissions
        class LastHourController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/courses/{course_id}/submissions/last_hour' do
            operation :get do
              key :description, 'Returns submissions to the course in the latest hour'
              key :produces, ['application/json']
              key :tags, ['submission']
              parameter '$ref': '#/parameters/path_course_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, 'Submission ids'
                schema do
                  key :type, :array
                  items do
                    key :type, :integer
                  end
                end
              end
            end
          end

          skip_authorization_check

          def index
            return respond_access_denied unless current_user.administrator?
            course = Course.find(params[:course_id])

            current_time = Time.current
            ids = course.submissions.where(created_at: (current_time - 1.hour)..current_time).ids
            present(ids)
          end
        end
      end
    end
  end
end
