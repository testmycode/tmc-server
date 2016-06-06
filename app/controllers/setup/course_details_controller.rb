class Setup::CourseDetailsController < Setup::SetupController

#  skip_authorization_check

  def edit

    authorize! :teach, @organization
    print_setup_breadcrumb(2)

    @course_template = CourseTemplate.find(params[:id])
    @course = Course.new_from_template(@course_template)
    @course.organization = @organization

  end

  def create
    authorize! :teach, @organization

    params = course_params_for_create_from_template

    input_name = params[:name]
    params[:name] = @organization.slug + '-' + input_name

    @course = Course.new(params)
    @course.organization = @organization

    if @course.save
      refresh_course(@course, no_directory_changes: @course.course_template.cache_exists?)
      redirect_to setup_organization_course_course_deadlines_path(@organization.slug, @course.id)
    else
      @course_template = @course.course_template
      @course.name = input_name
      print_setup_breadcrumb(2)
      render action: 'edit', notice: 'Course could not be created'
    end

  end

  private

  def refresh_course(course, options = {})
    begin
      session[:refresh_report] = course.refresh(options)
    rescue CourseRefresher::Failure => e
      session[:refresh_report] = e.report
    end
  end

  def course_params_for_create_from_template
    params.require(:course).permit(:name, :title, :description, :material_url, :course_template_id)
  end

end
