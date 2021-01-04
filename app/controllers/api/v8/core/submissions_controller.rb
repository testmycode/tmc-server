# frozen_string_literal: true

module Api
  module V8
    module Core
      class SubmissionsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/core/submissions/{submission_id}/download' do
          operation :get do
            key :description, 'Download the submission as a zip file'
            key :operationId, 'downloadSubmission'
            key :produces, ['application/zip']
            key :tags, ['core']
            parameter '$ref': '#/parameters/path_submission_id'
            response 200 do
              key :description, 'Submission zip file'
              schema do
                key :type, :file
              end
            end
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
          end
        end

        around_action :wrap_transaction

        def download
          unauthorize_guest!
          submission = Submission.find(params[:id])
          authorize! :download, submission

          send_data(submission.return_file, filename: "#{submission.user.login}-#{submission.exercise.name}-#{submission.id}.zip")
        end

        def show
          @submission = Submission.find_by!(id: params[:id])
          unless @submission.processed?
            authorization_skip!
            sandbox_status = :created
            if @submission.processing_began_at
              sandbox_status = :processing_on_sandbox
            elsif @submission.processing_tried_at
              sandbox_status = :sending_to_sandbox
            end
            status = :processing
            status = :hidden unless @submission.can_see_results?(current_user)
            return render json: {
              status: status,
              sandbox_status: sandbox_status
            }
          end
          unauthorize_guest!
          authorize! :read, @submission
          # This gets invalidated for the submitter when the results arrive so that they see the results right away.
          output = Rails.cache.fetch("api_v8_core_submission_show_#{@submission.id}_user_#{current_user.id}", expires_in: 30.seconds) do
            @course = @submission.course
            @exercise = @submission.exercise
            @organization = @course.organization
            output = {
              api_version: ApiVersion::API_VERSION,
              all_tests_passed: @submission.all_tests_passed?,
              user_id: @submission.user_id,
              login: @submission.user.login,
              course: @course.name,
              exercise_name: @submission.exercise.name,
              status: @submission.status(current_user),
              points: @submission.points_list,
              validations: @submission.validations,
              valgrind: @submission.valgrind,
              submission_url: submission_url(@submission),
              solution_url: @exercise.solution.visible_to?(current_user, true) ? view_context.exercise_solution_url(@exercise) : nil,
              submitted_at: @submission.created_at,
              processing_time: @submission.processing_time,
              reviewed: @submission.reviewed?,
              requests_review:  @submission.requests_review?,
              paste_url: @submission.paste_available ? paste_url(@submission.paste_key) : nil,
              message_for_paste: @submission.paste_available ? @submission.message_for_paste : nil,
              missing_review_points: @exercise.missing_review_points_for(@submission.user)
            }

            output = output.merge(
              case @submission.status(current_user)
              when :processing then {
                submissions_before_this: @submission.unprocessed_submissions_before_this,
                total_unprocessed: Submission.unprocessed_count
              }
              when :ok then {
                test_cases: @submission.test_case_records,
                feedback_questions: @course.feedback_questions.order(:position).map(&:record_for_api),
                feedback_answer_url: api_v8_core_submission_feedback_index_url(@submission, format: :json)
              }
              when :fail then {
                test_cases: @submission.test_case_records
              }
              when :hidden then {
                all_tests_passed:  nil,
                test_cases: [{ name: 'TestResultsAreHidden test', successful: true, message: nil, exception: nil, detailed_message: nil }],
                points: [],
                validations: nil,
                valgrind: nil
              }
              when :error then {
                error: @submission.pretest_error
              }
              end
            )
            output[:status] = :ok if output[:status] == :hidden && !can_handle_hidden_fields(params)
            if !!params[:include_files]
              output[:files] = SourceFileList.for_submission(@submission).map { |f| { path: f.path, contents: f.contents } }
            end
            output
          end

          render json: output
        end

        private
          def can_handle_hidden_fields(params)
            return false unless params[:client] == 'netbeans_plugin'
            splitted = params[:client_version].split('.')
            min_version = [1, 2, 5]
            min_version.each_with_index do |version_number, i|
              return false unless splitted[i]
              return false if splitted[i].to_i < version_number
              return true if splitted[i].to_i > version_number
            end
            true
          end
      end
    end
  end
end
