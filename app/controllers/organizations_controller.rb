require 'natsort'

class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :edit, :update, :destroy, :verify, :disable, :disable_reason_input, :toggle_visibility]

  skip_authorization_check only: [:index, :new]

  def index
    ordering = 'hidden, LOWER(name)'
    @organizations = Organization.accepted_organizations.order(ordering)
    @my_organizations = Organization.taught_organizations(current_user)
    @my_organizations |= Organization.assisted_organizations(current_user)
    @my_organizations |= Organization.participated_organizations(current_user)
    @my_organizations.natsort_by!(&:name)
  end

  def show
    add_organization_breadcrumb
    ordering = 'hidden, disabled_status, LOWER(courses.name)'
    @my_courses = Course.participated_courses(current_user, @organization).order(ordering).select { |c| c.visible_to?(current_user) }
    @my_assisted_courses = Course.assisted_courses(current_user, @organization).order(ordering).select { |c| c.visible_to?(current_user) }
    @ongoing_courses = @organization.courses.ongoing.order(ordering).select { |c| c.visible_to?(current_user) }
    @expired_courses = @organization.courses.expired.order(ordering).select { |c| c.visible_to?(current_user) }
    @my_courses_percent_completed = percent_completed_hash(@my_courses, current_user)
    authorize! :read, @ongoing_courses
    authorize! :read, @expired_courses
  end

  def new
    redirect_to new_setup_organization_path
  end

  def edit
    authorize! :edit, @organization
    add_organization_breadcrumb
    add_breadcrumb 'Edit'
    @cant_edit_slug = !current_user.administrator?
  end

  def update
    authorize! :edit, @organization
    authorize! :edit_slug, @organization unless organization_params[:slug].nil?

    if @organization.update(organization_params)
      redirect_to organization_path(@organization), notice: 'Organization was successfully updated.'
    else
      render :edit
    end
  end

  def list_requests
    authorize! :view, :unverified_organizations
    add_breadcrumb 'Unverified organizations'
    @unverified_organizations = Organization.pending_organizations
  end

  def verify
    authorize! :verify, :unverified_organizations
    if !@organization.verified
      @organization.verified = true
      @organization.verified_at = DateTime.now
      @organization.save
      redirect_to list_requests_organizations_path, notice: 'Organization is now verified.'
    else
      redirect_to organization_path(@organization)
    end
  end

  def disable_reason_input
    authorize! :disable, Organization
    add_organization_breadcrumb
    add_breadcrumb 'Disable organization'
  end

  def disable
    authorize! :disable, Organization
    if !@organization.disabled
      @organization.disabled = true
      @organization.disabled_reason = organization_params[:disabled_reason]
      @organization.save
      redirect_to list_requests_organizations_path, notice: "Organization #{@organization.name} successfully disabled."
    else
      redirect_to organization_path(@organization)
    end
  end

  def toggle_visibility
    authorize! :toggle_visibility, @organization
    @organization.hidden = !@organization.hidden
    @organization.save!
    redirect_to organization_path, notice: "Organization is now #{@organization.hidden ? 'hidden to users':'visible to users'}"
  end

  private

  def percent_completed_hash(courses, user)
    percent_completed = {}
    all_awarded = user.awarded_points.map(&:course_id)
    all_available = AvailablePoint.courses_points(courses).map(&:course_id)
    courses.each do |course|
      awarded = all_awarded.select { |id| id == course.id }.length.to_f
      available = all_available.select { |id| id == course.id }.length.to_f
      percent_completed[course.id] = 100 * (awarded / available)
    end
    percent_completed
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:id])
    fail ActiveRecord::RecordNotFound, 'Invalid organization id' if @organization.nil?
  end

  def organization_params
    params.require(:organization).permit(:name, :information, :logo, :slug, :contact_information, :phone, :email, :disabled_reason)
  end
end
