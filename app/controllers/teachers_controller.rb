# frozen_string_literal: true

class TeachersController < ApplicationController
  before_action :set_organization

  def index
    authorize! :teach, @organization
    ordering = 'LOWER(login)'
    @teachers = @organization.teachers.order(ordering)
    @teachership = Teachership.new
    add_organization_breadcrumb
    add_breadcrumb 'Manage teachers'
  end

  def create
    authorize! :teach, @organization

    user = User.find_by(email: teacher_params[:email])
    @teachership = Teachership.new(user: user, organization: @organization)

    if @teachership.save
      redirect_to organization_teachers_path, notice: "Teacher #{user.email} added to organization"
    else
      @teachers = @organization.teachers
      render :index
    end
  end

  def destroy
    authorize! :remove_teacher, @organization
    @teachership = Teachership.find(params[:id])
    destroyed_username = @teachership.user.login
    @teachership.destroy!
    redirect_to organization_teachers_path, notice: "Teacher #{destroyed_username} removed from organization"
  end

  private

    def set_organization
      @organization = Organization.find_by(slug: params[:organization_id])
    end

    def teacher_params
      params.permit(:email)
    end
end
