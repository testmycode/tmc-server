# frozen_string_literal: true

module Api
  module V8
    module Organizations
      module Courses
        class ExercisesController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}/exercises' do
            operation :get do
              key :description, 'Returns all exercises of the course as json. Course is searched by name'
              key :operationId, 'findExercisesByName'
              key :produces, ['application/json']
              key :tags, ['exercise']
              parameter '$ref': '#/parameters/path_organization_slug'
              parameter '$ref': '#/parameters/path_course_name'
              response 200 do
                key :description, 'Exercises in json'
                schema do
                  key :title, :exercises
                  key :required, [:exercises]
                  property :exercises do
                    key :type, :array
                    items do
                      key :'$ref', :ExerciseWithPoints
                    end
                  end
                end
              end
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
            end
          end

          swagger_path '/api/v8/org/{organization_slug}/courses/{course_name}/exercises/{exercise_name}/download' do
            operation :get do
              key :description, 'Download the exercise as a zip file'
              key :operationId, 'downloadExercise'
              key :produces, ['application/zip']
              key :tags, ['exercise']
              parameter '$ref': '#/parameters/path_organization_slug'
              parameter '$ref': '#/parameters/path_course_name'
              parameter '$ref': '#/parameters/path_exercise_name'
              response 200 do
                key :description, 'Exercise zip file'
                schema do
                  key :type, :file
                end
              end
              response 404, '$ref': '#/responses/error'
            end
          end

          def index
            unauthorize_guest!
            course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
            exercises = Exercise.includes(:available_points).where(course_id: course.id)

            visible = exercises.select { |ex| ex.visible_to?(current_user) }
            presentable = visible.map do |ex|
              {
                id: ex.id,
                available_points: ex.available_points,
                name: ex.name,
                publish_time: ex.publish_time,
                solution_visible_after: ex.solution_visible_after,
                deadline: ex.deadline_for(current_user),
                disabled: ex.disabled?
              }
            end

            authorize_collection :read, visible
            present(presentable)
          end

          def show
            authorization_skip!
            organization = Organization.find_by!(slug: params[:organization_slug])
            course = organization.courses.find_by(name: "#{params[:organization_slug]}-#{params[:course_name]}")
            course = organization.courses.find_by!(name: params[:course_name]) unless course
            ex = course.exercises.find_by!(name: params[:name])

            if current_user.guest?
              return render json: {
                id: ex.id,
                available_points: ex.available_points,
                deadline: ex.deadline_for(current_user),
                soft_deadline: ex.soft_deadline_for(current_user),
                expired: ex.expired_for?(current_user),
              }
            end

            model_solution_token_used_on_this_exercise = ModelSolutionTokenUsed.where(user: current_user, course: course, exercise_name: ex.name).count > 0

            total_model_solution_tokens = 0
            grant_model_solution_token_every_nth_completed_exercise = course.grant_model_solution_token_every_nth_completed_exercise
            begin
              authorize! :read, ex
            rescue CanCan::AccessDenied
              # If the exercise is not accessible, the user most likely has
              # a wrong course in the course settigns
              grant_model_solution_token_every_nth_completed_exercise = nil
            end
            if grant_model_solution_token_every_nth_completed_exercise && grant_model_solution_token_every_nth_completed_exercise > 0
              completed_exercises_count = course.submissions.where(all_tests_passed: true, user: current_user).distinct.select(:exercise_name).count
              total_model_solution_tokens = completed_exercises_count / grant_model_solution_token_every_nth_completed_exercise + (course.initial_coin_stash || 0)

              tokens_used = if course.large_exercises_consume_more_coins?
                ModelSolutionTokenUsed.where(user: current_user, course: course).sum(:cost)
              else
                ModelSolutionTokenUsed.where(user: current_user, course: course).count
              end
              available_model_solution_tokens = total_model_solution_tokens - tokens_used
            end

            present(
              id: ex.id,
              available_points: ex.available_points,
              awarded_points: ex.points_for(current_user),
              name: ex.name,
              publish_time: ex.publish_time,
              deadline: ex.deadline_for(current_user),
              soft_deadline: ex.soft_deadline_for(current_user),
              expired: ex.expired_for?(current_user),
              unlocked: ex.unlocked_for?(current_user),
              disabled: ex.disabled?,
              completed: ex.completed_by?(current_user),
              model_solution_token_used_on_this_exercise: model_solution_token_used_on_this_exercise,
              large_exercises_consume_more_coins: course.large_exercises_consume_more_coins?,
              email_verified: current_user.email_verified?,
              course: {
                grant_model_solution_token_every_nth_completed_exercise: grant_model_solution_token_every_nth_completed_exercise,
                total_model_solution_tokens: total_model_solution_tokens,
                available_model_solution_tokens: available_model_solution_tokens,
              }
            )
          end

          def download
            course = Course.find_by!(name: "#{params[:organization_slug]}-#{params[:course_name]}")
            exercise = Exercise.find_by!(name: params[:name], course_id: course.id)

            authorize! :download, exercise
            send_file exercise.stub_zip_file_path
          end
        end
      end
    end
  end
end
