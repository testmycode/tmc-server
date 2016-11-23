class Api::V8::Courses::SubmissionsController < Api::V8::BaseController
  include Swagger::Blocks

  swagger_path '/api/v8/courses/{course_id}/exercises/submissions' do
    operation :get do
      key :description, 'Returns the submissions visible to the user in a json format'
      key :operationId, 'findSubmissionsById'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'submission'
      ]
      parameter '$ref': '#/parameters/path_course_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Submissions in json'
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
    end
  end

  around_action :wrap_transaction

  def index
    unauthorize_guest!
    course = Course.find_by!(id: params[:course_id])
    submissions = Submission.where(course_id: course.id)
    readable = filter_fields(submissions.select { |sub| sub.readable_by?(current_user) })

    authorize_collection :read, readable
    present(readable)
  end

  private

  def filter_fields(submissions)
    submissions.map do |sub|
      {
          id: sub.id,
          user_id: sub.user_id,
          pretest_error: sub.pretest_error,
          created_at: sub.created_at,
          exercise_name: sub.exercise_name,
          course_id: sub.course_id,
          processed: sub.processed,
          all_tests_passed: sub.all_tests_passed,
          points: sub.points,
          processing_tried_at: sub.processing_tried_at,
          processing_began_at: sub.processing_began_at,
          processing_completed_at: sub.processing_completed_at,
          times_sent_to_sandbox: sub.times_sent_to_sandbox,
          processing_attempts_started_at: sub.processing_attempts_started_at,
          params_json: sub.params_json,
          requires_review: sub.requires_review,
          requests_review: sub.requests_review,
          reviewed: sub.reviewed,
          message_for_reviewer: sub.message_for_reviewer,
          newer_submission_reviewed: sub.newer_submission_reviewed,
          review_dismissed: sub.review_dismissed,
          paste_available: sub.paste_available,
          message_for_paste: sub.message_for_paste,
          paste_key: sub.paste_key
      }
    end
  end
end
