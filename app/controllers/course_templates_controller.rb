# typed: strict
# frozen_string_literal: true

class CourseTemplatesController < ApplicationController
  extend T::Sig
  before_action :set_course_template, except: %i[index new create list_for_teachers]

  sig { void }
  def index
    authorize! :read, CourseTemplate
    ordering = Arel.sql('LOWER(name)')
    add_breadcrumb 'Course templates', course_templates_path
    @course_templates = T.let(CourseTemplate.not_hidden.not_dummy.order(ordering), T.nilable(ActiveRecord::Relation))
    @hidden_course_templates = T.let(CourseTemplate.hidden.not_dummy.order(ordering), T.nilable(ActiveRecord::Relation))
    if request.params[:generate_report]
      @refresh_report = T.let(CourseTemplateRefresh.find(request.params[:generate_report]), T.nilable(CourseTemplateRefresh))
    end
  end

  sig { void }
  def show
    authorize! :read, CourseTemplate
    add_breadcrumb 'Course templates', course_templates_path
    add_breadcrumb T.must(@course_template).title.to_s
  end

  sig { void }
  def new
    authorize! :create, CourseTemplate
    add_breadcrumb 'Course templates', course_templates_path
    add_breadcrumb 'New Course template'
    @course_template = CourseTemplate.new
  end

  sig { void }
  def edit
    authorize! :edit, CourseTemplate
    add_breadcrumb 'Course templates', course_templates_path
    add_breadcrumb 'Edit Course template'
  end

  sig { void }
  def create
    authorize! :create, CourseTemplate
    @course_template = CourseTemplate.new(course_template_params)

    if @course_template.save
      redirect_to course_templates_path, notice: 'Course template was successfully created.'
    else
      render :new
    end
  end

  sig { void }
  def update
    authorize! :edit, CourseTemplate
    course_template = T.must(@course_template)
    if course_template.update(course_template_params)
      redirect_to course_templates_path, notice: "Course template '#{course_template.name}' was successfully updated."
    else
      render :edit
    end
  end

  sig { returns(T.noreturn) }
  def destroy
    raise 'One does not destroy a course template'
  end

  sig { void }
  def list_for_teachers
    @organization = Organization.find_by!(slug: params[:organization_id])
    authorize! :teach, @organization
    add_organization_breadcrumb
    add_breadcrumb 'Course templates'
    @course_templates = CourseTemplate.available.order(Arel.sql('LOWER(title)'))
  end

  sig { void }
  def toggle_hidden
    course_template = T.must(@course_template)
    course_template.hidden = !course_template.hidden
    course_template.save
    redirect_to course_templates_path, notice: 'Course templates hidden status changed'
  end

  sig { void }
  def refresh
    authorize! :create, CourseTemplate
    course_template = T.must(@course_template)
    notice = "Refresh initialized for course template #{course_template.name}"
    course_template.refresh(current_user.id)
    redirect_to course_templates_path(id: course_template.id), notice: notice
  end

  private
    sig { void }
    def set_course_template
      authorize! params[:action].to_sym, CourseTemplate
      @course_template = T.let(CourseTemplate.find(params[:id]), T.nilable(CourseTemplate))
    end

    sig { returns(ActionController::Parameters) }
    def course_template_params
      params.require(:course_template).permit(:name, :title, :description, :material_url, :source_url, :expires_at, :git_branch)
    end
end
