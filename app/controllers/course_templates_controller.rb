class CourseTemplatesController < ApplicationController
  before_action :set_course_template, only: [:edit, :update, :destroy]

  def index
    authorize! :read, CourseTemplate
    @course_templates = CourseTemplate.all
  end

  def new
    authorize! :create, CourseTemplate
    @course_template = CourseTemplate.new
  end

  def edit
  end

  def create
    authorize! :create, CourseTemplate
    @course_template = CourseTemplate.new(course_template_params)

    if @course_template.save
      redirect_to course_templates_path, notice: 'Course template was successfully created.'
    else
      render :new
    end
  end

  def update
    if @course_template.update(course_template_params)
      redirect_to course_templates_path, notice: 'Course template was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @course_template.destroy
    redirect_to course_templates_url, notice: 'Course template was successfully destroyed.'
  end

  def list_for_teachers
    organization_slug = params[:id]
    authorize! :teach, Organization.find_by_slug(organization_slug)
    @course_templates = CourseTemplate.all
  end

  private

  def set_course_template
    authorize! params[:action].to_sym, CourseTemplate
    @course_template = CourseTemplate.find(params[:id])
  end

  def course_template_params
    params.require(:course_template).permit(:name, :title, :description, :material_url, :source_url)
  end
end
