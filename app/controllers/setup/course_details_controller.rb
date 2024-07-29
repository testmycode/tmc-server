# frozen_string_literal: true

require 'course_refresh_database_updater'

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
      # Do refresh if custom course and course_template first course
      if custom || !@course.course_template.cache_exists?
        refresh_course(@course)
      else
        template_refresh = @course.course_template.course_template_refreshes.last
        CourseRefreshDatabaseUpdater.new.refresh_course(@course, template_refresh[:langs_refresh_output])
      end
      update_setup_course(@course.id)
      redirect_to setup_organization_course_course_assistants_path(@organization.slug, @course.id)
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
        redirect_to setup_organization_course_course_assistants_path(@organization.slug, @course.id),
                    notice: 'Course details updated.'
      else
        redirect_to organization_course_path(@organization, @course), notice: 'Course details updated.'
      end
    else
      render :edit
    end
  end

  private
    def refresh_course(course)
      course.refresh(current_user.id)
    end

    def course_params_for_create_from_template
      params.require(:course).permit(:name, :title, :description, :material_url, :course_template_id, :moocfi_id)
    end

    def course_params_for_create_custom
      params.require(:course).permit(:name, :title, :description, :material_url, :source_url, :git_branch, :source_backend, :moocfi_id)
    end

    def course_params
      if @course.custom?
        params.require(:course).permit(:title, :description, :material_url, :source_url, :git_branch, :external_scoreboard_url, :moocfi_id)
      else
        params.require(:course).permit(:title, :description, :material_url, :external_scoreboard_url, :moocfi_id)
      end
    end
end
