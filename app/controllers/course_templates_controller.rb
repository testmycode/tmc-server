class CourseTemplatesController < ApplicationController
  before_action :set_course_template, only: [:edit, :update, :destroy]

  # GET /course_templates
  def index
    authorize! :read, CourseTemplate
    @course_templates = CourseTemplate.all
  end

  # GET /course_templates/new
  def new
    authorize! :create, CourseTemplate
    @course_template = CourseTemplate.new
  end

  # GET /course_templates/1/edit
  def edit
  end

  # POST /course_templates
  def create
    authorize! :create, CourseTemplate
    @course_template = CourseTemplate.new(course_template_params)

    if @course_template.save
      redirect_to @course_template, notice: 'Course template was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /course_templates/1
  def update
    if @course_template.update(course_template_params)
      redirect_to @course_template, notice: 'Course template was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /course_templates/1
  def destroy
    @course_template.destroy
    redirect_to course_templates_url, notice: 'Course template was successfully destroyed.'
  end

  def list_for_teachers
    organization_slug = params[:id] #change :id to :organization_id
    authorize! :teach, Organization.find_by_slug(organization_slug)
    @course_templates = CourseTemplate.all
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course_template
    authorize! params[:action].to_sym, CourseTemplate
    @course_template = CourseTemplate.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def course_template_params
    params.require(:course_template).permit(:name, :title, :description, :material_url, :source_url)
  end
end
