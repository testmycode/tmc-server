module Api
  module V8
    module Core
      module Organizations
        class CoursesController < Api::V8::BaseController

          include Swagger::Blocks

          swagger_path '/api/v8/core/org/{organization_id}/courses/{course_id}' do
            operation :get do
              key :description, "Returns the course details in a json format. Course is searched by id"
              key :produces, ['application/json']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_organization_id'
              parameter '$ref': '#/parameters/path_course_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, 'Course details in json'
                schema do
                  key :title, :course
                  key :required, [:course]
                  property :course do
                    key :type, :array
                    items do
                      key :'$ref', :CoreCourseDetails
                    end
                  end
                end
              end
            end
          end

          def show
            unauthorize_guest!
            course = Course.find_by!(id: params[:id])
            authorize! :read, course
            organization = Organization.find_by(slug: params[:organization_slug])
            data = {course: CourseInfo.new(current_user, view_context).course_data_core_api(organization, course)}
            present data
          end

        end
      end
    end
  end
end