class Setup::CourseChooserController < Setup::SetupController
  before_action :set_organization

  def index
    authorize! :teach, @organization
    print_setup_phases(1)
    @course_templates = CourseTemplate.available.order('LOWER(title)')
  end
end
