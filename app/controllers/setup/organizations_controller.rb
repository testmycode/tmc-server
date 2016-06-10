class Setup::OrganizationsController < Setup::SetupController

  skip_authorization_check only: [:index]

  def index
    redirect_to setup_start_index_path
  end

  def new
    authorize! :request, :organization
    add_breadcrumb 'Setup'
    add_breadcrumb 'Create new organization'
    @organization = Organization.new
  end

  def create
    authorize! :request, :organization
    @organization = Organization.init(organization_params, current_user)

    if !@organization.errors.any?
      redirect_to organization_path(@organization), notice: 'Organization was successfully created.'
    else
      render :new
    end
  end

  def organization_params
    params.require(:organization).permit(:name, :information, :logo, :slug, :contact_information, :phone, :email, :disabled_reason)
  end

end
