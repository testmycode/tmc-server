class CourseTemplatesController < ApplicationController
  before_action :set_course_template, only: [:edit, :update, :destroy, :prepare_course, :toggle_hidden]

  def index
    authorize! :read, CourseTemplate
    ordering = 'LOWER(name)'
    add_breadcrumb 'Course templates', course_templates_path
    @course_templates = CourseTemplate.all.order(ordering)
  end

  def new
    authorize! :create, CourseTemplate
    add_breadcrumb 'Course templates', course_templates_path
    add_breadcrumb 'New Course template'
    @course_template = CourseTemplate.new
  end

  def edit
    authorize! :edit, CourseTemplate
    add_breadcrumb 'Course templates', course_templates_path
    add_breadcrumb 'Edit Course template'
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
    authorize! :edit, CourseTemplate
    if @course_template.update(course_template_params)
      redirect_to course_templates_path, notice: 'Course template was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, CourseTemplate
    @course_template.destroy
    redirect_to course_templates_path, notice: 'Course template was successfully destroyed.'
  end

  def list_for_teachers
    @organization = Organization.find_by(slug: params[:organization_id])
    authorize! :teach, @organization
    add_organization_breadcrumb
    add_breadcrumb 'Course templates'
    @course_templates = CourseTemplate.available
  end

  def prepare_course
    @organization = Organization.find_by(slug: params[:organization_id])
    authorize! :teach, @organization
    authorize! :clone, @course_template
    add_organization_breadcrumb
    add_breadcrumb 'Course templates', organization_course_templates_path
    add_breadcrumb 'Create new course'
    @course = Course.new name: @course_template.name,
                         title: @course_template.title,
                         description: @course_template.description,
                         material_url: @course_template.material_url,
                         source_url: @course_template.source_url
  end

  def toggle_hidden
    @course_template.hidden = !@course_template.hidden
    @course_template.save
    redirect_to course_templates_path, notice: 'Course templates hidden status changed'
  end

  private

  def set_course_template
    authorize! params[:action].to_sym, CourseTemplate
    @course_template = CourseTemplate.find(params[:id])
  end

  def course_template_params
    params.require(:course_template).permit(:name, :title, :description, :material_url, :source_url, :expires_at)
  end
end
