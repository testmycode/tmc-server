# typed: strict
# frozen_string_literal: true

require 'natsort'

class OrganizationsController < ApplicationController
  extend T::Sig
  before_action :set_organization, only: %i[show verify disable disable_reason_input toggle_visibility all_courses]

  skip_authorization_check only: %i[index new all_courses]

  sig { void }
  def index
    ordering = Arel.sql('hidden, LOWER(name)')
    organizations = Organization
                    .accepted_organizations
                    .with_attached_logo
                    .order(ordering)
                    .reject { |org| (org.hidden? && !can?(:view_hidden_organizations, nil)) || !org.visibility_allowed?(request, current_user) }
    @organizations = T.let(organizations, T.nilable(T::Array[Organization]))
    my_organizations = Organization.taught_organizations(current_user).with_attached_logo.select { |org| org.visibility_allowed?(request, current_user) }
    my_organizations |= Organization.assisted_organizations(current_user).with_attached_logo.select { |org| org.visibility_allowed?(request, current_user) }
    my_organizations |= Organization.participated_organizations(current_user).with_attached_logo.select { |org| org.visibility_allowed?(request, current_user) }
    my_organizations.natsort_by!(&:name)
    @my_organizations = T.let(my_organizations, T.nilable(T::Array[Organization]))
    @courses_under_initial_refresh = T.let(Course.where(initial_refresh_ready: false), T.nilable(ActiveRecord::Relation))
    pinned_organizations = Organization
                           .accepted_organizations
                           .where(pinned: true)
                           .with_attached_logo
                           .order(ordering)
                           .select { |org| org.visibility_allowed?(request, current_user) }
                           .reject { |org| org.hidden? && !can?(:view_hidden_organizations, nil) }
    @pinned_organizations = T.let(pinned_organizations, T.nilable(T::Array[Organization]))
    render layout: 'landing'
  end

  sig { void }
  def show
    add_organization_breadcrumb
    organization = T.must(@organization)
    ordering = Arel.sql('hidden, disabled_status, LOWER(courses.title)')
    my_assisted_courses = Course.assisted_courses(current_user, organization).order(ordering).select { |c| c.visible_to?(current_user) }
    @my_assisted_courses = T.let(my_assisted_courses, T.nilable(T::Array[Course]))
    ongoing_courses = organization
                      .courses
                      .ongoing
                      .enabled
                      .where(hidden: false)
                      .order(ordering)
                      .select { |c| c.visible_to?(current_user) }
                      .to_a
    if can? :teach, organization
      recently_updated_disabled_courses = organization.courses
                                                       .ongoing
                                                       .disabled
                                                       .where(updated_at: Time.current.all_quarter)
                                                       .to_a
      ongoing_courses += recently_updated_disabled_courses
    end
    @ongoing_courses = T.let(ongoing_courses, T.nilable(T::Array[Course]))
    authorize! :read, ongoing_courses
  end

  sig { void }
  def all_courses
    return respond_forbidden('This feature is only for teachers and administrators.') unless current_user.administrator? || current_user.teacher?(@organization)
    add_organization_breadcrumb
    add_breadcrumb 'All Courses'
    organization = T.must(@organization)
    ordering = 'hidden, disabled_status, LOWER(courses.title)'

    @my_assisted_courses = Course.assisted_courses(current_user, organization).order(ordering).select { |c| c.visible_to?(current_user) }
    ongoing_courses = organization.courses.ongoing.order(ordering).select { |c| c.visible_to?(current_user) }
    expired_courses = organization.courses.expired.order(ordering).select { |c| c.visible_to?(current_user) }
    @ongoing_courses = ongoing_courses
    @expired_courses = T.let(expired_courses, T.nilable(T::Array[Course]))
    authorize! :read, ongoing_courses
    authorize! :read, expired_courses
  end

  sig { void }
  def new
    redirect_to new_setup_organization_path
  end

  sig { void }
  def list_requests
    authorize! :view, :unverified_organizations
    add_breadcrumb 'Unverified organizations'
    @unverified_organizations = T.let(Organization.pending_organizations, T.nilable(ActiveRecord::Relation))
  end

  sig { void }
  def verify
    authorize! :verify, :unverified_organizations
    organization = T.must(@organization)
    if !organization.verified
      organization.verified = true
      organization.verified_at = Time.current
      organization.save!
      redirect_to organizations_path, notice: "Organization #{organization.name} is now verified."
    else
      redirect_to organization_path(organization)
    end
  end

  sig { void }
  def disable_reason_input
    authorize! :disable, Organization
    add_organization_breadcrumb
    add_breadcrumb 'Disable organization'
  end

  sig { void }
  def disable
    authorize! :disable, Organization
    organization = T.must(@organization)
    if !organization.disabled
      organization.disabled = true
      organization.disabled_reason = organization_params[:disabled_reason]
      organization.save
      redirect_to list_requests_organizations_path, notice: "Organization #{organization.name} successfully disabled."
    else
      redirect_to organization_path(organization)
    end
  end

  sig { void }
  def toggle_visibility
    authorize! :toggle_visibility, @organization
    organization = T.must(@organization)
    organization.hidden = !organization.hidden
    organization.save!
    redirect_to organization_path, notice: "Organization is now #{organization.hidden ? 'hidden to users' : 'visible to users'}"
  end

  private
    sig { params(courses: T.untyped, user: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
    def percent_completed_hash(courses, user)
      percent_completed = {}
      all_awarded = AwardedPoint.all_awarded(user)
      all_available = AvailablePoint.courses_points(courses).map(&:course_id)
      courses.each do |course|
        awarded = all_awarded.count { |id| id == course.id }.to_f
        available = all_available.count { |id| id == course.id }.to_f
        percent_completed[course.id] = 100 * (awarded / available) unless course.hide_submission_results
      end
      percent_completed
    end

    sig { void }
    def set_organization
      @organization = Organization.find_by!(slug: params[:id])
      unauthorized! unless @organization.visibility_allowed?(request, current_user)
    end

    sig { returns(ActionController::Parameters) }
    def organization_params
      params.require(:organization).permit(:name, :information, :logo, :slug, :contact_information, :phone, :email, :disabled_reason)
    end
end
