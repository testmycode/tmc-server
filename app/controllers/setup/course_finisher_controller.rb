class Setup::CourseFinisherController < Setup::SetupController

  before_action :set_course

  def index
    authorize! :teach, @organization

    print_setup_breadcrumb(5)

  end

  def create
    #TODO: Publish / enable

    redirect_to organization_course_path(@organization, @course)
  end


end
