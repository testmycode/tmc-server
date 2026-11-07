# typed: strict
# frozen_string_literal: true

require 'student_submission_migrator'

class MigrateToOtherCourseController < ApplicationController
  extend T::Sig
  sig { void }
  def show
    old_course = Course.find(params[:course_id])
    to_course = Course.find(params[:id])
    @old_course = T.let(old_course, T.nilable(Course))
    @to_course = T.let(to_course, T.nilable(Course))

    authorize! :read, to_course
    authorize! :read, current_user

    @already_migrated = T.let(already_migrated, T.nilable(T::Boolean))
    @extra_alert_text = T.let(get_extra_text, T.nilable(String))
    return respond_with_error('Please login to continue') if current_user.guest?
    respond_with_error('This migration is not allowed') unless StudentSubmissionMigrator.new(old_course, to_course, current_user).migration_is_allowed
  end

  sig { void }
  def migrate
    @old_course = Course.find(params[:course_id])
    @to_course = Course.find(params[:id])

    authorize! :read, @to_course

    if check_understanding!
      StudentSubmissionMigrator.new(@old_course, @to_course, current_user).migrate!
      flash[:notice] = 'Successfully migrated over'
      redirect_to participant_path(current_user)
    else
      flash[:alert] = 'Improper answers. Please try again'
      render :show
    end
  end

  private
    sig { returns(T::Boolean) }
    def check_understanding!
      return false unless params[:from_course_name].strip == T.must(@old_course).name
      return false unless params[:to_course_name].strip == T.must(@to_course).name
      return false unless params[:im_sure]

      !already_migrated
    end

    sig { returns(T::Boolean) }
    def already_migrated
      MigratedSubmissions.where(to_course_id: T.must(@to_course).id, original_submission_id: current_user.submissions.where(course: @old_course).pluck(:id)).any?
    end

    sig { returns(T.nilable(String)) }
    def get_extra_text
      allowed_migrations = SiteSetting.value(:allow_migrations_between_courses)
      return nil if allowed_migrations.nil?
      allowed_migrations.each do |allowed_pair|
        return allowed_pair['message'] if allowed_pair['from'] == T.must(@old_course).id && allowed_pair['to'] == T.must(@to_course).id
      end
      nil
    end
end
