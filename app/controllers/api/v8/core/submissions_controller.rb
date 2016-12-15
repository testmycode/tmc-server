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
      end
    end
  end
end
