# frozen_string_literal: true

class Setup::CourseDetailsController < Setup::SetupController
  before_action :set_course, except: %i[new create]

  def new
    authorize! :teach, @organization
    @course_template = CourseTemplate.find(params[:template_id])
    authorize! :clone, @course_template

    print_setup_phases(2)

    @course = Course.new_from_template(@course_template)
    @course.organization = @organization
  end

  def custom
    authorize! :create, :custom_course
    print_setup_phases(2)

    @course = Course.new
    @course.organization = @organization
    @custom = true
    render 'new'
  end

  def create
    authorize! :teach, @organization

    custom = params[:course][:course_template_id].blank?

    create_params = custom ? course_params_for_create_custom : course_params_for_create_from_template
    input_name = create_params[:name]
    create_params[:name] = @organization.slug + '-' + input_name

    @course = Course.new(create_params)
    @course.organization = @organization

    if @course.save
      # Fast refresh without time-consuming tasks, like making solutions
      refresh_course(@course, no_directory_changes: @course.course_template.cache_exists?, no_background_operations: true)
      # Full refresh happens as background task

      update_setup_course(@course.id)
      redirect_to setup_organization_course_course_timing_path(@organization.slug, @course.id)
    else
      @course_template = @course.course_template unless custom
      @course.name = input_name
      print_setup_phases(2)
      @custom = custom
      render action: 'new', notice: 'Course could not be created'
    end
  end

  def edit
    authorize! :teach, @organization
    @setup_in_progress = setup_in_progress?
    if setup_in_progress?
      print_setup_phases(2)
    else
      add_course_breadcrumb
      add_breadcrumb('Edit details')
    end
  end

  def update
    authorize! :teach, @organization
    if @course.update(course_params)
      if setup_in_progress?
        redirect_to setup_organization_course_course_timing_path(@organization.slug, @course.id),
                    notice: 'Course details updated.'
      else
        redirect_to organization_course_path(@organization, @course), notice: 'Course details updated.'
      end
    else
      render :edit
    end
  end

  private
    def refresh_course(course, options = {})
      # TODO: Could include course ID

      session[:refresh_report] = course.refresh(current_user, options)
    rescue CourseRefresher::Failure => e
      session[:refresh_report] = e.report
    end

    def course_params_for_create_from_template
      params.require(:course).permit(:name, :title, :description, :material_url, :course_template_id)
    end

    def course_params_for_create_custom
      params.require(:course).permit(:name, :title, :description, :material_url, :source_url, :git_branch, :source_backend)
    end

    def course_params
      if @course.custom?
        params.require(:course).permit(:title, :description, :material_url, :source_url, :git_branch, :external_scoreboard_url)
      else
        params.require(:course).permit(:title, :description, :material_url, :external_scoreboard_url)
      end
    end
end
