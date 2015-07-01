class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :edit, :update, :destroy, :accept, :reject, :reject_reason_input, :toggle_visibility]

  skip_authorization_check only: [:index]

  def index
    ordering = 'LOWER(name)'
    @organizations = Organization.accepted_organizations.order(ordering)
  end

  def show
    add_organization_breadcrumb
    ordering = 'hidden, disabled_status, LOWER(name)'
    @ongoing_courses = @organization.courses.ongoing.order(ordering).select { |c| c.visible_to?(current_user) }
    @expired_courses = @organization.courses.expired.order(ordering).select { |c| c.visible_to?(current_user) }
    authorize! :read, @ongoing_courses
    authorize! :read, @expired_courses
  end

  def new
    authorize! :request, :organization
    add_breadcrumb 'Create new organization'
    @organization = Organization.new
  end

  def edit
    authorize! :edit, @organization
    add_organization_breadcrumb
    add_breadcrumb 'Edit'
  end

  def create
    authorize! :request, :organization
    @organization = Organization.init(organization_params, current_user)

    if !@organization.errors.any?
      redirect_to organization_path(@organization), notice: 'Organization was successfully requested.'
    else
      render :new
    end
  end

  def update
    authorize! :edit, @organization
    if @organization.update(organization_params)
      redirect_to organization_path(@organization), notice: 'Organization was successfully updated.'
    else
      render :edit
    end
  end

  def list_requests
    authorize! :view, :organization_requests
    add_breadcrumb 'New organization requests'
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
      redirect_to organization_path(@organization)
    end
  end

  def reject_reason_input
    authorize! :reject, :organization_requests
    add_breadcrumb 'New organization requests', list_requests_organizations_path
    add_breadcrumb 'Reject organization'
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
      redirect_to organization_path(@organization)
    end
  end

  def toggle_visibility
    authorize! :toggle_visibility, @organization
    @organization.hidden = !@organization.hidden
    @organization.save!
    redirect_to organization_path, notice: "Organzation is now #{@organization.hidden ? 'hidden to users':'visible to users'}"
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:id])
    fail ActiveRecord::RecordNotFound, 'Invalid organization id' if @organization.nil?
  end

  def organization_params
    params.require(:organization).permit(:name, :information, :logo, :slug, :rejected_reason)
  end
end
