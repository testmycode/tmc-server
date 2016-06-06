class Setup::CourseChooserController < Setup::SetupController

  before_action :set_organization

  def index
    authorize! :teach, @organization

    add_breadcrumb 'Setup', :setup_path
    add_breadcrumb '1. Course template',

    @course_templates = CourseTemplate.available.order('LOWER(title)')

  end

end
