class PointsController < ApplicationController
  skip_authorization_check

  def index
    if current_user.guest?
      raise CanCan::AccessDenied.
        new("Access denied to points.", :read, AwardedPoint)
    end
    @course = Course.find(params[:course_id])
    users = User.course_students(@course).sort!
    sheets = @course.gdocs_sheets.sort!
    @summary = summary_hash(@course, users, sheets)
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

  def summary_hash course, users, sheets
    {
      :sheets => sheets.map{|sheet| {
        :name => sheet,
        :available => AvailablePoint.course_sheet_points(course, sheet).count,
        :awarded => AwardedPoint.course_sheet_points(course, sheet).count
      }},
      :awarded => AwardedPoint.course_points(course).count,
      :available => AvailablePoint.course_points(course).count,
      :students => users.map{|u| {
        :login => u.login,
        :points => sheets.reduce({}){ |hash, sheet|
          hash.merge({ sheet => AwardedPoint.
            course_user_sheet_points(course, u, sheet).count })
          },
        :awarded => AwardedPoint.course_user_points(course, u).count
      }}
    }
  end
end
