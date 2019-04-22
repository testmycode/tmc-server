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

            authorize! :teach, course

            applied_students = UserAppDatum.where(field_name: 'applies_for_study_right', value: 't', namespace: 'ohjelmoinnin-mooc-2019').pluck(:user_id)

            groups = course.exercise_groups[0..6] + course.exercise_groups[8..13]

            cbu = course.exercise_group_completion_by_user

            user_ids = groups.flat_map { |group| ap = cbu[group.name][:available_points]; cbu[group.name][:points_by_user].map { |k, v| { k => (v.to_f / ap) } } }.group_by { |o| o.keys.first }.map { |k, v| { k => v.map { |o2| o2[k] } } }.inject(:merge).select { |_k, v| v.length == groups.length }.select { |_k, v| v.all? { |o2| o2 >= 0.8995 } }.map { |k, _v| k }

            eligble_ids = (user_ids & applied_students)
            users = User.where(id: eligble_ids)

            if params[:extra_fields]
              namespace = params[:extra_fields]
              user_id_to_extra_fields = UserAppDatum.where(namespace: namespace, user: users).group_by(&:user_id)
            end

            eligible_students = users.map do |u|
              d = {
                id: u.id,
                username: u.login,
                email: u.email,
                administrator: u.administrator
              }
              if user_id_to_extra_fields
                extra_fields = user_id_to_extra_fields[u.id] || []
                d[:extra_fields] = extra_fields.map { |o| [o.field_name, o.value] }.to_h
              end
              if params[:user_fields]
                user_fields = u.user_field_values.map { |o| [o.field_name, o.value] }.to_h
                d[:user_fields] = user_fields
                d[:student_number] = user_fields['organizational_id']
                d[:first_name] = user_fields['first_name']
                d[:last_name] = user_fields['last_name']
              end
              d
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
