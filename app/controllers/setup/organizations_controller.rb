class Setup::OrganizationsController < Setup::SetupController
  skip_authorization_check only: [:index, :new]

  def index
    redirect_to setup_start_index_path
  end

  def new
    return respond_access_denied('Please log in first to create new organization') if !can? :request, :organization
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

  def edit
    authorize! :edit, @organization

    add_organization_breadcrumb
    add_breadcrumb 'Edit details'
    @cant_edit_slug = !current_user.administrator?
  end

  def update
    authorize! :edit, @organization
    authorize! :edit_slug, @organization unless organization_params[:slug].nil?

    if @organization.update(organization_params)
      redirect_to organization_path(@organization), notice: 'Organization was successfully updated.'
    else
      add_organization_breadcrumb
      add_breadcrumb 'Edit details'
      @cant_edit_slug = !current_user.administrator?
      render :edit
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:id]) unless params[:id].nil?
  end

  def organization_params
    params.require(:organization).permit(:name, :information, :website, :logo, :slug, :contact_information, :phone, :email, :disabled_reason)
  end
end
