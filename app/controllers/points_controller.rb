class PointsController < ApplicationController
  skip_authorization_check

  def index
    if current_user.guest?
      raise CanCan::AccessDenied.
        new("Access denied to points.", :read, AwardedPoint)
    end
    @course = Course.find(params[:course_id])
    @users = User.course_students(@course)
    @sheets = @course.gdocs_sheets
  end

  def show
    if current_user.guest?
      raise CanCan::AccessDenied.
        new("Access denied to points.", :read, AwardedPoint)
    end
    @sheetname = params[:id]
    @course = Course.find(params[:course_id])

    @sheets = @course.gdocs_sheets
    @users = User.course_students(@course)
    @exercises = Exercise.course_gdocs_sheet_exercises(@course, @sheetname)
  end
end
