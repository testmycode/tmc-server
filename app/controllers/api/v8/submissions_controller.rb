class Api::V8::SubmissionsController < Api::V8::BaseController
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

  swagger_path '/api/v8/courses/{course_id}/exercises/submissions/user' do
    operation :get do
      key :description, 'Returns the user\'s own submissions in a json format'
      key :operationId, 'findUsersOwnSubmissionsById'
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
        key :description, 'User\'s own submissions in json'
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

  swagger_path '/api/v8/courses/{course_id}/exercises/submissions/user/{user_id}' do
    operation :get do
      key :description, 'Returns the submissions visible to the user in a json format'
      key :operationId, 'findUsersSubmissionsById'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'submission'
      ]
      parameter '$ref': '#/parameters/path_course_id'
      parameter '$ref': '#/parameters/path_user_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'User\'s submissions in json'
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

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/submissions' do
    operation :get do
      key :description, 'Returns the submissions visible to the user in a json format'
      key :operationId, 'findSubmissions'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'submission'
      ]
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
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

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/submissions/user' do
    operation :get do
      key :description, 'Returns the user\'s own submissions in a json format'
      key :operationId, 'findUsersOwnSubmissionsByCourseName'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'submission'
      ]
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'User\'s own submissions in json'
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

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/submissions/user/{user_id}' do
    operation :get do
      key :description, 'Returns the submissions visible to the user in a json format'
      key :operationId, 'findUsersSubmissionsByCourseName'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'submission'
      ]
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      parameter '$ref': '#/parameters/path_user_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'User\'s submissions in json'
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

  def get_submissions_all
    unauthorize_guest!
    course = Course.find_by!(id: params[:course_id]) if params[:course_id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    submissions = Submission.where(course_id: course.id)
    readable = filter_fields(submissions.select { |sub| sub.readable_by?(current_user) })

    authorize_collection :read, readable
    present(readable)
  end

  def get_submissions_user
    unauthorize_guest!
    course = Course.find_by!(id: params[:course_id]) if params[:course_id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    params[:user_id] = current_user.id unless params[:user_id]
    submissions = Submission.where(course_id: course.id, user_id: params[:user_id])
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
          stdout: sub.stdout,
          stderr: sub.stderr,
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
