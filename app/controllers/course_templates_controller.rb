class CourseTemplatesController < ApplicationController
  before_action :set_course_template, except: [:index, :new, :create, :list_for_teachers]

  def index
    authorize! :read, CourseTemplate
    ordering = 'LOWER(name)'
    add_breadcrumb 'Course templates', course_templates_path
    @course_templates = CourseTemplate.not_hidden.not_dummy.order(ordering)
    @hidden_course_templates = CourseTemplate.hidden.not_dummy.order(ordering)
    if session[:template_refresh_report]
      @template_refresh_report = session[:template_refresh_report]
      session.delete(:template_refresh_report)
    end
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
    raise "One does not destroy a course template"
  end

  def list_for_teachers
    @organization = Organization.find_by(slug: params[:organization_id])
    authorize! :teach, @organization
    add_organization_breadcrumb
    add_breadcrumb 'Course templates'
    @course_templates = CourseTemplate.available.order('LOWER(title)')
  end

  def toggle_hidden
    @course_template.hidden = !@course_template.hidden
    @course_template.save
    redirect_to course_templates_path, notice: 'Course templates hidden status changed'
  end

  def refresh
    notice = 'Course template successfully refreshed'
    begin
      session[:template_refresh_report] = @course_template.refresh
    rescue CourseRefresher::Failure => e
      notice = "Refresh failed, something went wrong:<br><br>#{e}"
    end
    redirect_to course_templates_path, notice: notice
  end

  private

  def set_course_template
    authorize! params[:action].to_sym, CourseTemplate
    @course_template = CourseTemplate.find(params[:id])
  end

  def course_template_params
    params.require(:course_template).permit(:name, :title, :description, :material_url, :source_url, :expires_at, :git_branch)
  end
end
