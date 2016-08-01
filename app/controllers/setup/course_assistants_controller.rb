class Setup::CourseAssistantsController < Setup::SetupController
  before_action :set_course

  def index
    authorize! :teach, @organization
    @setup_in_progress = setup_in_progress?

    @assistants = @course.assistants
    @assistantship = Assistantship.new

    if setup_in_progress?
      print_setup_phases(4)
    else
      add_breadcrumb("Assistants for course #{@course.title}")
    end

  end

  def create
    authorize! :teach, @organization

    if params[:commit] == 'Add new assistant'
      new_assistant = User.find_by(login: assistant_params[:username])
      @assistantship = Assistantship.new(user: new_assistant, course: @course)

      if @assistantship.save
        redirect_to setup_organization_course_course_assistants_path, notice: "Assistant #{new_assistant.login} added"
      else
        @assistants = @course.assistants
        if setup_in_progress?
          print_setup_phases(4)
        else
          add_breadcrumb("Assistants for course #{@course.title}")
        end
        render :index
      end
    elsif params[:commit] == 'Continue'
      redirect_to setup_organization_course_course_finisher_index_path
    else
      redirect_to organization_course_path(@organization, @course)
    end
  end

  def destroy
    authorize! :remove_assistant, @course
    @assistantship = Assistantship.find(params[:id])
    destroyed_username = @assistantship.user.login
    @assistantship.destroy!
    redirect_to setup_organization_course_course_assistants_path, notice: "Assistant #{destroyed_username} removed from course."
  end

  private

  def assistant_params
    params.permit(:username)
  end
end
