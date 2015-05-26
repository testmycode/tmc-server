class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :edit, :update, :destroy, :accept, :reject, :reject_reason_input]

  skip_authorization_check only: [:index, :show]

  def index
    @organizations = Organization.accepted_organizations
  end

  def show
  end

  def new
    authorize! :create, :organization
    @organization = Organization.new
  end

  def edit
    authorize! :edit, @organization
  end

  def create
    authorize! :create, :organization
    @organization = Organization.init(organization_params, current_user)

    if !@organization.errors.any?
      redirect_to @organization, notice: 'Organization was successfully requested.'
    else
      render :new
    end
  end

  def update
    authorize! :edit, @organization
    if @organization.update(organization_params)
      redirect_to @organization, notice: 'Organization was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @organization
    @organization.destroy
    redirect_to organizations_url, notice: 'Organization was successfully destroyed.'
  end

  def list_requests
    authorize! :view, :organization_requests
    @requested_organizations = Organization.pending_organizations
  end

  def accept
    authorize! :accept, :organization_requests
    if @organization.acceptance_pending
      @organization.acceptance_pending = false
      @organization.accepted_at = DateTime.now
      @organization.save
      redirect_to list_requests_organizations_path, notice: 'Organization request was successfully accepted.'
    else
      redirect_to organizations_path
    end
  end

  def reject_reason_input
    authorize! :reject, :organization_requests
  end

  def reject
    authorize! :reject, :organization_requests
    if @organization.acceptance_pending
      @organization.acceptance_pending = false
      @organization.rejected = true
      @organization.rejected_reason = organization_params[:rejected_reason]
      @organization.save
      redirect_to list_requests_organizations_path, notice: 'Organization request was successfully rejected.'
    else
      redirect_to organizations_path
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:id])
    fail ActiveRecord::RecordNotFound, 'Invalid organization id' if @organization.nil?
  end

  def organization_params
    params.require(:organization).permit(:name, :information, :slug, :rejected_reason)
  end
end
