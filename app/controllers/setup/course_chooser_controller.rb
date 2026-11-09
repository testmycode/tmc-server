# typed: strict
# frozen_string_literal: true

class Setup::CourseChooserController < Setup::SetupController
  extend T::Sig
  before_action :set_course_from_session

  sig { void }
  def index
    authorize! :teach, @organization
    save_wizard_to_session(1)
    print_setup_phases(1)
    @course_templates = T.let(CourseTemplate.available.order(Arel.sql('LOWER(title)')), T.nilable(ActiveRecord::Relation))
    @setup_in_progress = T.let(setup_in_progress?, T.nilable(T::Boolean))
  end

  private
    sig { void }
    def set_course_from_session
      if setup_in_progress? && !session[:ongoing_course_setup][:course_id].nil?
        @course = Course.find(session[:ongoing_course_setup][:course_id])
      end
    end
end
