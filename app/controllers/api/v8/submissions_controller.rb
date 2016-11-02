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
      response 401, '$ref': '#/responses/error'
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

  swagger_path '/api/v8/courses/{course_id}/submissions' do
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
      response 401, '$ref': '#/responses/error'
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
      response 401, '$ref': '#/responses/error'
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
      response 401, '$ref': '#/responses/error'
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
    @course = Course.lock('FOR SHARE').find_by(name: "#{params[:slug]}-#{params[:course_name]}") || Course.lock('FOR SHARE').find_by(id: params[:course_id])
    authorize! :read, @course

    @organization = @course.organization
    @submissions = Submission.where(course_id: @course.id)
    filter_submissions(@submissions)
  end

  def users_submissions
    @course = Course.lock('FOR SHARE').find(params[:course_id])
    @user = User.find(params[:user_id])
    authorize! :read, @user
    authorize! :read, @course

    @submissions = Submission.where(course_id: @course.id, user_id: @user.id)
    filter_submissions(@submissions)
  end

  def my_submissions
    @user = current_user
    authorize! :read, @user
    @course = Course.lock('FOR SHARE').find(params[:course_id])
    authorize! :read, @course

    @submissions = Submission.where(course_id: @course.id, user_id: @user.id)
    filter_submissions(@submissions)
  end

  private

  def course_transaction
    Course.transaction(requires_new: true) do
      yield
    end
  end

  def render_json(array)
    if array.empty?
      render json: {
        error: "You are not signed in!"
      }
    else
      render json: {
        submissions: array
      }
    end
  end

  def filter_submissions(subs)
    visible_submissions = []
    subs.each do |submission|
      next unless submission.readable_by?(current_user)
      visible_submissions.push(submission)
    end

    authorize! :read, visible_submissions

    render_json(visible_submissions)
  end
end
