class Setup::CourseFinisherController < Setup::SetupController

  before_action :set_course

  def index
    authorize! :teach, @organization

    print_setup_phases(5)
  end

  def create
    authorize! :teach, @organization

    if params[:commit] == 'Publish now'
      @course.enabled!
    else
      @course.disabled!
    end
    @course.save!
    redirect_to organization_course_path(@organization, @course)
  end
end
