class Api::V8::SubmissionsController < Api::V8::BaseController
  include Swagger::Blocks

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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or organization not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
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

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/submissions/{user_id}' do
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'User, course or organization not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
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

  swagger_path '/api/v8/courses/{course_id}/exercises/submissions/{user_id}' do
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'User or course not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
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

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/submissions/mine' do
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or organization not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
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

  swagger_path '/api/v8/courses/{course_id}/exercises/submissions/mine' do
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
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

  around_action :wrap_transaction

  def all_submissions
    course = Course.find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.find(params[:course_id])
    authorize! :read, course

    submissions = filter_submissions(authorized_content(Submission.where(course_id: course.id)))

    present(submissions)
  end

  def users_submissions
    user = User.find(params[:user_id])
    authorize! :read, user

    course = Course.find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.find(params[:course_id])
    authorize! :read, course

    submissions = filter_submissions(authorized_content(Submission.where(course_id: course.id, user_id: user.id)))

    present(submissions)
  end

  def my_submissions
    user = current_user
    authorize! :read, user

    course = Course.find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.find(params[:course_id])
    authorize! :read, course
    
    submissions = filter_submissions(authorized_content(Submission.where(course_id: course.id, user_id: user.id)))

    present(submissions)
  end

  private

  def filter_submissions(submissions)
    filtered_fields = submissions.map do |sub|
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
