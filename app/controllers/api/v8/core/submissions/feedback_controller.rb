# frozen_string_literal: true

module Api
  module V8
    module Core
      module Submissions
        class FeedbackController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/core/submissions/{submission_id}/feedback' do
            operation :post do
              key :description, 'Submits a feedback for submission'
              key :operationId, 'submitFeedback'
              key :produces, ['application/json']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_submission_id'
              response 200 do
                key :description, 'Submits feedback'
                schema do
                  key :title, :status
                  key :required, [:status]
                  property :status do
                    key :type, :array
                    items do
                      key :type, :object
                      property :answer do
                        key :type, :string
                      end
                      property :question_id do
                        key :type, :integer
                      end
                    end
          end
                end
              end
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
            end
          end

          def create
            submission = Submission.find(params[:submission_id])
            authorize! :read, submission

            answer_params = params[:answers]
            answer_params = answer_params.values if answer_params.respond_to?(:values)

            answer_records = answer_params.map do |answer_hash|
              FeedbackAnswer.new(submission: submission,
                                 course_id: submission.course_id,
                                 exercise_name: submission.exercise_name,
                                 feedback_question_id: answer_hash[:question_id],
                                 answer: answer_hash[:answer])
            end

            answer_records.each { |record| authorize! :create, record }
            begin
              ActiveRecord::Base.connection.transaction(requires_new: true) do
                answer_records.each(&:save!)
              end
            rescue StandardError
              ::Rails.logger.warn "Failed to save feedback answer: #{$!}\n#{$!.backtrace.join("\n  ")}"
              return respond_with_error("Failed to save feedback answer: #{$!}")
            end

            respond_to do |format|
              format.html do
                flash[:success] = 'Feedback saved.'
                redirect_to submission_path(submission)
              end
              format.json do
                render json: { api_version: 8, status: 'ok' }
              end
            end
          end
        end
      end
    end
  end
end
