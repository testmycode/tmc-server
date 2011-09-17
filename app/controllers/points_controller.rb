class PointsController < ApplicationController
  skip_authorization_check

  def index
    if current_user.guest?
      raise CanCan::AccessDenied.
        new("Access denied to points.", :read, AwardedPoint)
    end
    @course = Course.find(params[:course_id])
    @users = User.course_students(@course).sort!
    @sheets = @course.gdocs_sheets.sort!
  end

  def show
    if current_user.guest?
      raise CanCan::AccessDenied.
        new("Access denied to points.", :read, AwardedPoint)
    end
    @sheetname = params[:id]
    @course = Course.find(params[:course_id])

    @users = User.course_sheet_students(@course, @sheetname).sort!
    @exercises = Exercise.
      course_gdocs_sheet_exercises(@course, @sheetname).sort!
  end
end
