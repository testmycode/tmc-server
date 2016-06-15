class Setup::CourseAssistantsController < Setup::SetupController

  before_action :set_course

  def index
    authorize! :teach, @organization

    # TODO: List all assistants
    #@assistants = @course.assistants ## Only if assistants would be shown...
    @assistantship = Assistantship.new

    print_setup_breadcrumb(4)

  end

  def create
    authorize! :teach, @organization

    if params[:commit] == 'Add new assistant'
      new_assistant = User.find_by(login: assistant_params[:username])
      @assistantship = Assistantship.new(user: new_assistant, course: @course)

      if @assistantship.save
        redirect_to setup_organization_course_course_assistants_path, notice: "Assistant #{new_assistant.login} added"
      else
        print_setup_breadcrumb(4)
        render :index
      end
    else
      # Continue to next step
      redirect_to setup_organization_course_course_finisher_index_path
    end
  end

  def assistant_params
    params.permit(:username)
  end

end
