class Api::V8::SubmissionsController < ApplicationController # ApplicationController --> BaseController sit ku PR merged
  include Swagger::Blocks

  swagger_path '/api/v8/org/:organization_id//courses/:course_name/submissions' do
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

  around_action :course_transaction
  before_action :get_course_and_user

  def all_submissions
    @submissions = Submission.where(course_id: @course.id)
    binding.pry
    visible_submissions = []
    @submissions.each do |submission|
      next unless submission.readable_by?(current_user)
      visible_submissions.push(submission)
    end

    authorize! :read, visible_submissions

    render json: {
      submissions: visible_submissions
    }
  end

  private

  def course_transaction
    Course.transaction(requires_new: true) do
      yield
    end
  end

  def get_course_and_user
    if params[:course_name]
      @course = Course.lock('FOR SHARE').find_by(name: params[:course_name])
      @organization = @course.organization
      authorize! :read, @course
    elsif params[:course_id]
      @course = Course.lock('FOR SHARE').find(params[:course_id])
      @organization = @course.organization
      authorize! :read, @course
    elsif params[:user_id]
      @user = User.find(params[:user_id])
      authorize! :read, @user
    elsif current_user
      @user = current_user
      authorize! :read, @user
    else
      respond_access_denied
    end
  end
end
