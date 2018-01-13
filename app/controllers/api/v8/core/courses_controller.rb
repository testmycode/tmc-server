module Api
  module V8
    module Core
      class CoursesController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/core/courses/{course_id}' do
          operation :get do
            key :description, 'Returns the course details in a json format. Course is searched by id'
            key :produces, ['application/json']
            key :tags, ['core']
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
          if params[:client] == 'netbeans_plugin' && params[:client_version] = '1.1.9'
            authorization_skip!
            return respond_with_error("You need to update your client. You can do that by selecting 'Help' -> 'Check for updates' and then following instructions.", 404, nil, obsolete_client: true)
          end
          course = Course.find_by!(id: params[:id])
          authorize! :read, course
          data = { course: CourseInfo.new(current_user, view_context).course_data_core_api(course) }
          present data
        end
      end
    end
  end
end
