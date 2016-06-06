class Setup::CourseTimingsController < Setup::SetupController

#  skip_authorization_check
  before_action :set_course

  def show
    authorize! :teach, @organization
    print_setup_breadcrumb(3)

  end

  def update
    authorize! :teach, @organization

    #TODO: Formin käsittely

#    byebug
    if params[:commit] == 'Accept and continue'
      path = setup_organization_course_course_assistants_path
      redirect_to path
    elsif params[:commit] == 'Show preview'
      print_setup_breadcrumb(3)
      byebug
      render action: :show, notice: 'Blah'
    else
      raise 'asd'
    end


  end

end
