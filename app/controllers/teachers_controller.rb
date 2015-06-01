class TeachersController < ApplicationController
  before_action :set_teacher, only: [:destroy]
  before_action :set_organization

  def index
    authorize! :teach, @organization
    @teachers = @organization.teachers
  end

  def new
    authorize! :teach, @organization
    @teachership = Teachership.new
  end

  def create
    authorize! :teach, @organization

    user = User.find_by(login: teacher_params[:username])
    @teachership = Teachership.new(user: user, organization: @organization)

    if @teachership.save
      redirect_to organization_teachers_path, notice: 'Teacher added to organization'
    else
      render :new
    end
  end

  def destroy
    authorize! :teach, @organization
  end

  private

  def set_teacher
    @teachership = Teachership.find(params[:id])
    @teacher = @teachership.user
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end

  def teacher_params
    params.permit(:username)
  end
end
