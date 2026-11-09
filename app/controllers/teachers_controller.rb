# typed: strict
# frozen_string_literal: true

class TeachersController < ApplicationController
  extend T::Sig
  before_action :set_organization

  sig { void }
  def index
    authorize! :teach, @organization
    ordering = Arel.sql('LOWER(login)')
    @teachers = T.let(T.must(@organization).teachers.order(ordering), T.nilable(ActiveRecord::Relation))
    @teachership = T.let(Teachership.new, T.nilable(Teachership))
    add_organization_breadcrumb
    add_breadcrumb 'Manage teachers'
  end

  sig { void }
  def create
    authorize! :teach, @organization

    user = User.find_by(email: teacher_params[:email])
    @teachership = Teachership.new(user: user, organization: @organization)

    if @teachership.save
      redirect_to organization_teachers_path, notice: "Teacher #{T.must(user).email} added to organization"
    else
      @teachers = T.must(@organization).teachers
      render :index
    end
  end

  sig { void }
  def destroy
    authorize! :remove_teacher, @organization
    @teachership = T.must(@organization).teacherships.find(params[:id])
    destroyed_username = T.must(@teachership.user).login
    @teachership.destroy!
    redirect_to organization_teachers_path, notice: "Teacher #{destroyed_username} removed from organization"
  end

  private
    sig { void }
    def set_organization
      @organization = Organization.find_by!(slug: params[:organization_id])
    end

    sig { returns(ActionController::Parameters) }
    def teacher_params
      params.permit(:email)
    end
end
