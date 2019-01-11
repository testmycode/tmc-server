# frozen_string_literal: true

module Api
  module V8
    module Core
      class ExercisesController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/core/exercises/{exercise_id}/download' do
          operation :get do
            key :description, 'Download the exercise as a zip file'
            key :operationId, 'downloadExercise'
            key :produces, ['application/zip']
            key :tags, ['core']
            parameter '$ref': '#/parameters/path_exercise_id'
            response 200 do
              key :description, 'Exercise zip file'
              schema do
                key :type, :file
              end
            end
            response 404, '$ref': '#/responses/error'
          end
        end

        swagger_path '/api/v8/core/exercises/{exercise_id}' do
          operation :get do
            key :description, 'Returns information about exercise and its submissions. Used by tmc-core'
            key :operationId, 'findExercisesById'
            key :produces, ['application/json']
            key :tags, ['core']
            parameter '$ref': '#/parameters/path_exercise_id'
            response 200 do
              key :description, 'Exercises in json'
              schema do
                key :title, :exercises
                key :required, [:exercises]
                property :exercises do
                  key :type, :array
                  items do
                    key :'$ref', :CoreExercise
                  end
                end
              end
            end
            response 403, '$ref': '#/responses/error'
          end
        end

        def download
          exercise = Exercise.find(params[:id])

          authorize! :download, exercise
          send_file exercise.stub_zip_file_path
        end

        def show
          unauthorize_guest!
          exercise = Exercise.find(params[:id])
          course = Course.find(exercise.course_id)
          authorize! :read, course
          authorize! :read, exercise

          submissions = exercise.submissions.order('submissions.created_at DESC')
          submissions = submissions.where(user_id: current_user.id) unless current_user.administrator?
          submissions = submissions.includes(:awarded_points).includes(:user)
          authorize! :read, submissions

          data = {
            course_name: course.name,
            course_id: course.id,
            code_review_requests_enabled: exercise.code_review_requests_enabled?,
            run_tests_locally_action_enabled: exercise.run_tests_locally_action_enabled?,
            exercise_name: exercise.name,
            exercise_id: exercise.id,
            unlocked_at: exercise.time_unlocked_for(current_user),
            deadline: exercise.deadline_for(current_user),
            submissions: SubmissionList.new(current_user, view_context).submission_list_data(submissions)
          }
          present data
        end
      end
    end
  end
end
