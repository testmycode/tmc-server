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

  around_action :course_transaction

  def all_submissions
    course = Course.find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.lock('FOR SHARE').find_by(id: params[:course_id])
    authorize! :read, course

    organization = course.organization

    submissions = Submission.where(course_id: course.id).readable(current_user)
    authorize! :read, submissions

    render_json(submissions)
  end

  def users_submissions
    user = User.find(params[:user_id])
    authorize! :read, user

    course = Course.find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.lock('FOR SHARE').find(params[:course_id])
    authorize! :read, course

    submissions = Submission.where(course_id: course.id, user_id: user.id).readable(current_user)
    submissions.each do |s|
      authorize! :read, s
    end

    render_json(submissions)
  end

  def my_submissions
    user = current_user
    authorize! :read, user

    course = Course.find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.lock('FOR SHARE').find(params[:course_id])
    authorize! :read, course

    submissions = Submission.where(course_id: course.id, user_id: user.id).readable(current_user)
    authorize! :read, submissions

    render_json(submissions)
  end

  private

  def course_transaction
    Course.transaction(requires_new: true) do
      yield
    end
  end

  def render_json(array)
      unauthorized!("You are not signed in!") if array.empty?

      render json: {
        submissions: array
      }
  end
end
