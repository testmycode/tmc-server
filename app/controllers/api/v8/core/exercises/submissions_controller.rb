# frozen_string_literal: true

module Api
  module V8
    module Core
      module Exercises
        class SubmissionsController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/core/exercises/{exercise_id}/submissions' do
            operation :post do
              key :description, 'Create submission from a zip file'
              key :operationId, 'createSubmission'
              key :produces, ['application/json']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_exercise_id'
              response 200 do
                key :description, 'Submission json'
                schema do
                  key :title, :submissions
                  key :required, [:submissions]
                  property :submissions do
                    key :type, :array
                    items do
                      key :'$ref', :Submission
                    end
                  end
                end
              end
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
            end
          end

          around_action :wrap_transaction

          def create
            unauthorize_guest!

            @exercise = Exercise.find(params[:exercise_id])
            authorize! :read, @exercise
            @course = @exercise.course
            authorize! :read, @course

            if !params[:submission] || !params[:submission][:file]
              authorization_skip!
              return respond_not_found('No ZIP file selected or failed to receive it')
            end

            unless @exercise.submittable_by?(current_user)
              authorization_skip!
              return respond_forbidden('Submissions for this exercise are no longer accepted.')
            end

            file_contents = File.read(params[:submission][:file].tempfile.path)

            errormsg = nil

            unless file_contents.start_with?('PK')
              errormsg = "The uploaded file doesn't look like a ZIP file."
            end

            submission_params = {
              error_msg_locale: params[:error_msg_locale]
            }

            low_priority = Submission.where(created_at: (Time.now - 10.minutes)..Time.now, user: current_user).count > 3

            unless errormsg
              @submission = Submission.new(
                user: current_user,
                course: @course,
                exercise: @exercise,
                return_file: file_contents,
                params_json: submission_params.to_json,
                requests_review: !params[:request_review].nil?,
                paste_available: !params[:paste].nil?,
                message_for_paste: if params[:paste]
                                     params[:message_for_paste] || ''
                                   else
                                     ''
                                   end,
                message_for_reviewer: if params[:request_review]
                                        params[:message_for_reviewer] || ''
                                      else
                                        ''
                                      end,
                client_time: if params[:client_time]
                               Time.at(params[:client_time].to_i)
                             end,
                client_nanotime: params[:client_nanotime],
                client_ip: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip,
                processing_priority: low_priority ? -100 : 0
              )

              authorize! :create, @submission

              unless @submission.save
                errormsg = 'Failed to save submission.'
                errormsg += " Errors: #{@submission.errors.messages}"
              end
            end

            unless errormsg
              # SubmissionProcessor.new.process_submission(@submission)
            end

            if !errormsg
              render json: { submission_url: api_v8_core_submission_url(@submission),
                             paste_url: @submission.paste_key ? paste_url(@submission.paste_key) : '',
                             show_submission_url: submission_url(@submission) }
            else
              render json: { error: errormsg }
            end
          end
        end
      end
    end
  end
end
