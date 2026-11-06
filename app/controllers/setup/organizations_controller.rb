# typed: strict
# frozen_string_literal: true

class Setup::OrganizationsController < Setup::SetupController
  extend T::Sig
  skip_authorization_check only: %i[index new]

  sig { void }
  def index
    redirect_to setup_start_index_path
  end

  sig { void }
  def new
    return respond_unauthorized('Please log in first to create new organization') unless can? :request, :organization
    add_breadcrumb 'Create new organization'
    @organization = Organization.new
  end

  sig { void }
  def create
    authorize! :request, :organization
    @organization = Organization.init(organization_params, current_user)

    if @organization.errors.none?
      redirect_to organization_path(@organization), notice: 'Organization was successfully created.'
      # TODO: Background task
      NewOrganizationRequestMailer.request_email(@organization).deliver_now
    else
      render :new
    end
  end

  sig { void }
  def edit
    authorize! :edit, @organization

    add_organization_breadcrumb
    add_breadcrumb 'Edit details'
    @cant_edit_slug = T.let(!current_user.administrator?, T.nilable(T::Boolean))
  end

  sig { void }
  def update
    authorize! :edit, @organization
    authorize! :edit_slug, @organization unless organization_params[:slug].nil?

    if T.must(@organization).update(organization_params)
      redirect_to organization_path(@organization), notice: 'Organization was successfully updated.'
    else
      add_organization_breadcrumb
      add_breadcrumb 'Edit details'
      @cant_edit_slug = !current_user.administrator?
      render :edit
    end
  end

  private
    sig { void }
    def set_organization
      @organization = Organization.find_by!(slug: params[:id]) unless params[:id].nil?
    end

    sig { returns(ActionController::Parameters) }
    def organization_params
      params.require(:organization).permit(:name, :information, :website, :logo, :slug, :contact_information, :phone, :email, :disabled_reason)
    end
end
