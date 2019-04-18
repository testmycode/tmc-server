# frozen_string_literal: true

module Api
  module V8
    module Organizations
      module Courses
        class StudyrightEligibilityController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}/eligible_students' do
            operation :get do
              key :description, "Returns all users from the course who have at least 90% of every part's points and are applying for study right, in a json format. Course is searched by name, only 2019 programming mooc course is valid"
              key :produces, ['application/json']
              key :tags, ['point']
              parameter '$ref': '#/parameters/path_organization_slug'
              parameter '$ref': '#/parameters/path_course_name'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, 'Users in json'
                schema do
                  key :type, :array
                  items do
                    key :'$ref', :UserBasicInfo
                  end
                end
              end
            end
          end

          skip_authorization_check

          def eligible_students
            unauthorize_guest!

            return respond_with_error("This feature is only for MOOC-organization's 2019 programming MOOC") unless params[:course_name] == '2019-ohjelmointi' && params[:organization_slug] == 'mooc'

            course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")

            authorize! :read, course

            applied_students = UserAppDatum.where(field_name: 'applies_for_study_right', value: 't', namespace: 'ohjelmoinnin-mooc-2019').each { |datum| datum.user_id }

            authorize! :read, applied_students

            eligible_student_ids = []

            applied_students.map do |user|
              drop = false
              course.exercise_group_completion_counts_for_user(user).map do |group, info|
                if info[:progress] < 0.9
                  drop = true
                end
              end
              eligible_student_ids.push(user) unless drop
            end

            eligible_students = []

            eligible_student_ids.map do |user_id|
              u = User.find(user_id)
              info = {
                id: u.id,
                username: u.login,
                email: u.email,
                administrator: u.administrator
              }
              eligible_students.push(info)
            end

            render json: {
              eligible_students: eligible_students
            }
          end
        end
      end
    end
  end
end
