# frozen_string_literal: true

module Api
  module V8
    module Courses
      class AllCoursesWithThisTemplateController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/courses/{course_id}/all_courses_with_this_template' do
          operation :get do
            key :description, 'Returns all courses with a same template in a json format'
            key :operationId, 'findAllCoursesWithThisTemplate'
            key :produces, [
              'application/json'
            ]
            key :tags, [
              'template'
            ]
            parameter '$ref': '#/parameters/path_course_id'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, 'Courses from same template in json'
              schema do
                key :title, :courses
                key :required, [:courses]
                property :courses do
                  key :type, :array
                  items do
                    key :'$ref', :Course
                  end
                end
              end
            end
          end
        end

        def index
          unauthorize_guest!
          course = Course.find_by!(id: params[:course_id])
          courses = Course.where(course_template_id: course[:course_template_id])
          authorize! :read, courses
          present(courses)
        end
      end
    end
  end
end
