class AssistantsController < ApplicationController
  before_action :set_course

  def index
    authorize! :teach, @course.organization
    @assistants = @course.assistants
  end

  def new
    authorize! :teach, @course.organization
    @assistantship = Assistantship.new
  end

  def create
    authorize! :teach, @course.organization

    user = User.find_by(login: assistant_params[:username])
    @assistantship = Assistantship.new(user: user, course: @course)

    if @assistantship.save
      redirect_to organization_course_assistants_path, notice: 'Assistant added to course'
    else
      render :new
    end
  end

  private

  def set_course
    @course = Course.find_by id: params[:course_id]
  end

  def assistant_params
    params.permit(:username)
  end
end
