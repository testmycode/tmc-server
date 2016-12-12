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

        swagger_path 'api/v8/core/exercises/{exercise.id}/submissions' do
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

        def download
          unauthorize_guest!
          submission = Submission.find(params[:id])
          authorize! :download, submission

          send_data(submission.return_file, filename: "#{submission.user.login}-#{submission.exercise.name}-#{submission.id}.zip")
        end

        def create
          unauthorize_guest!

          if !params[:submission] || !params[:submission][:file]
            authorization_skip!
            return respond_not_found('No ZIP file selected or failed to receive it')
          end

          unless @exercise.submittable_by?(current_user)
            authorization_skip!
            return respond_access_denied('Submissions for this exercise are no longer accepted.')
          end

          file_contents = File.read(params[:submission][:file].tempfile.path)

          errormsg = nil

          unless file_contents.start_with?('PK')
            errormsg = "The uploaded file doesn't look like a ZIP file."
          end

          submission_params = {
              error_msg_locale: params[:error_msg_locale]
          }

          unless errormsg
            @submission = Submission.new(
                user: current_user,
                course: @course,
                exercise: @exercise,
                return_file: file_contents,
                params_json: submission_params.to_json,
                requests_review: !!params[:request_review],
                paste_available: !!params[:paste],
                message_for_paste: if params[:paste] then params[:message_for_paste] || '' else '' end,
                message_for_reviewer: if params[:request_review] then params[:message_for_reviewer] || '' else '' end,
                client_time: if params[:client_time] then Time.at(params[:client_time].to_i) else nil end,
                client_nanotime: params[:client_nanotime],
                client_ip: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
            )

            authorize! :create, @submission

            unless @submission.save
              errormsg = 'Failed to save submission.'
            end
          end

          unless errormsg
            SubmissionProcessor.new.process_submission(@submission)
          end

          if !errormsg
            render json: { submission_url: submission_url(@submission, format: 'json', api_version: ApiVersion::API_VERSION),
                           paste_url: if @submission.paste_key then paste_url(@submission.paste_key) else '' end }
          else
            render json: { error: errormsg }
          end
        end
      end
    end
  end
end
