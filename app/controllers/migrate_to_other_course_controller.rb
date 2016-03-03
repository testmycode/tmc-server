class MigrateToOtherCourseController < ApplicationController

  def show
    @old_course = Course.find(params[:course_id])
    @to_course = Course.find(params[:id])

    authorize! :read, @old_course
    authorize! :read, @to_course

    @already_migrated = already_migrated
    @extra_alert_text = get_extra_text
    return respond_with_error("This migration is not allowed") if !StudentSubmissionMigrator.new(@old_course, @to_course, current_user).migration_is_allowed || current_user.guest?
  end

  def migrate
    @old_course = Course.find(params[:course_id])
    @to_course = Course.find(params[:id])

    authorize! :read, @old_course
    authorize! :read, @to_course

    if check_understanding!
      StudentSubmissionMigrator.new(@old_course, @to_course, current_user).migrate!
      flash[:notice] = "Successfully migrated over"
      redirect_to participant_path(current_user)
    else
      flash[:alert] = "Inproper answers. Please try again"
      render :show
    end
  end

  private

  def check_understanding!
    params[:from_course_name] == @old_course.name &&
    params[:to_course_name] == @to_course.name &&
    params[:username] == current_user.login &&
    !!params[:im_sure] &&
    !already_migrated
  end

  def already_migrated
    MigratedSubmissions.where(to_course_id: @to_course.id, original_submission_id: current_user.submissions.where(course: @old_course).pluck(:id)).any?
  end

  def get_extra_text
    allowed_migrations = SiteSetting.value(:allow_migrations_between_courses)
    return nil if allowed_migrations.nil?
    allowed_migrations.each do |allowed_pair|
      puts allowed_pair
      return allowed_pair['message'] if allowed_pair['from'] == @old_course.id && allowed_pair['to'] == @to_course.id
    end
    nil
  end
end
