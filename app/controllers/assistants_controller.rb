class AssistantsController < ApplicationController
  before_action :set_course

  def index
    @organization = @course.organization
    authorize! :teach, @organization
    add_course_breadcrumb
    add_breadcrumb 'Manage assistants'
    @assistants = @course.assistants
    @assistantship = Assistantship.new
  end

  def create
    authorize! :teach, @course.organization

    user = User.find_by(login: assistant_params[:username])
    @assistantship = Assistantship.new(user: user, course: @course)

    if @assistantship.save
      redirect_to organization_course_assistants_path, notice: 'Assistant added to course'
    else
      @assistants = @course.assistants
      render :index
    end
  end

  def destroy
    authorize! :remove_assistant, @course
    @assistantship = Assistantship.find(params[:id])
    @assistantship.destroy!
    redirect_to organization_course_assistants_path, notice: 'Assistant removed from course'
  end

  private

  def set_course
    @course = Course.find_by! name: params[:course_name]
  end

  def assistant_params
    params.permit(:username)
  end
end
