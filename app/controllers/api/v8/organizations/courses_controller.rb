# frozen_string_literal: true

module Api
  module V8
    module Organizations
      class CoursesController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}' do
          operation :get do
            key :description, "Returns the course's information in a json format. Course is searched by organization slug and course name"
            key :produces, ['application/json']
            key :tags, ['course']
            parameter '$ref': '#/parameters/path_organization_slug'
            parameter '$ref': '#/parameters/path_course_name'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, 'Course in json'
              schema do
                key :title, :course
                key :required, [:course]
                property :course, '$ref': :Course
              end
            end
          end
        end

        def show
          unauthorize_guest!
          course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:name]}")
          authorize! :read, course
          present course.course_as_json
        end
      end
    end
  end
end
