# typed: strict
# frozen_string_literal: true

# Receives explicit unlock requests and shows a web UI for making them.
class UnlocksController < ApplicationController
  extend T::Sig
  sig { void }
  def show
    @course = Course.find(params[:course_id])
    authorize! :read, @course
    @organization = Organization.find_by(slug: params[:organization_id])
    @exercises = T.let(@course.unlockable_exercises_for(current_user), T.nilable(T::Array[Exercise]))

    respond_to do |format|
      format.html do
        add_course_breadcrumb
        add_breadcrumb 'Unlock exercises', organization_course_unlock_path
      end
    end
  end

  sig { void }
  def create
    @course = Course.find(params[:course_id])
    authorize! :read, @course
    @organization = Organization.find_by(slug: params[:organization_id])
    @exercises = @course.unlockable_exercises_for(current_user)

    Unlock.unlock_exercises(@exercises, current_user)

    respond_to do |format|
      format.html do
        flash[:success] = 'Exercises unlocked.'
        redirect_to organization_course_path(@organization, @course)
      end
      format.json do
        render json: { status: 'ok' }
      end
    end
  end
end
