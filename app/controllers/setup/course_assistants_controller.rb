# typed: strict
# frozen_string_literal: true

class Setup::CourseAssistantsController < Setup::SetupController
  before_action :set_course

  sig { void }
  def index
    authorize! :modify_assistants, @course
    course = T.must(@course)
    @setup_in_progress = T.let(setup_in_progress?, T.nilable(T::Boolean))

    @assistants = T.let(course.assistants, T.nilable(ActiveRecord::Relation))
    @assistantship = T.let(Assistantship.new, T.nilable(Assistantship))

    if setup_in_progress?
      print_setup_phases(3)
    else
      add_breadcrumb("Assistants for course #{course.title}")
    end
  end

  sig { void }
  def create
    authorize! :modify_assistants, @course
    course = T.must(@course)

    if params[:commit] == 'Add new assistant'
      new_assistant = User.find_by('lower(email) = ?', assistant_params[:email].downcase)
      @assistantship = Assistantship.new(user: new_assistant, course: course)

      if @assistantship.save
        redirect_to setup_organization_course_course_assistants_path, notice: "Assistant #{T.must(new_assistant).email} added"
      else
        @setup_in_progress = setup_in_progress?
        @assistants = course.assistants
        if setup_in_progress?
          print_setup_phases(3)
        else
          add_breadcrumb("Assistants for course #{course.title}")
        end
        render :index
      end
    elsif params[:commit] == 'Continue'
      redirect_to setup_organization_course_course_finisher_index_path
    else
      redirect_to organization_course_path(@organization, course)
    end
  end

  sig { void }
  def destroy
    authorize! :modify_assistants, @course
    @assistantship = T.must(@course).assistantships.find(params[:id])
    destroyed_email = T.must(@assistantship.user).email
    @assistantship.destroy!
    redirect_to setup_organization_course_course_assistants_path, notice: "Assistant #{destroyed_email} removed from course."
  end

  private
    sig { returns(ActionController::Parameters) }
    def assistant_params
      params.permit(:email)
    end
end
