# frozen_string_literal: true

class Setup::CourseChooserController < Setup::SetupController
  before_action :set_course_from_session

  def index
    authorize! :teach, @organization
    save_wizard_to_session(1)
    print_setup_phases(1)
    @course_templates = CourseTemplate.available.order('LOWER(title)')
    @setup_in_progress = setup_in_progress?
  end

  private

    def set_course_from_session
      if setup_in_progress? && !session[:ongoing_course_setup][:course_id].nil?
        @course = Course.find(session[:ongoing_course_setup][:course_id])
      end
    end
end
