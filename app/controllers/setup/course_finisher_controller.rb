# frozen_string_literal: true

class Setup::CourseFinisherController < Setup::SetupController
  before_action :set_course

  def index
    authorize! :teach, @organization
    unless setup_in_progress?
      redirect_to setup_start_index_path, notice: 'No active course setup going on.'
    end
    print_setup_phases(5)
  end

  def create
    authorize! :teach, @organization

    if params[:commit] == 'Publish now'
      @course.enabled!
      @course.save!
    elsif params[:commit] == 'Finish and publish later'
      @course.disabled!
      @course.save!
    end

    reset_setup_session
    redirect_to organization_course_path(@organization, @course)
  end
end
