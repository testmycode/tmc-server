class PointsController < ApplicationController
  include PointsHelper
  skip_authorization_check :except => :refresh_gdocs

  def index
    @course = Course.find(params[:course_id])
    users = User.course_students(@course).sort!
    sheets = @course.gdocs_sheets.sort!
    @summary = summary_hash(@course, users, sheets)
  end

  def refresh_gdocs
    authorize! :refresh, @course
    @sheetname = params[:id]
    @course = Course.find(params[:course_id])
    @notifications = @course.refresh_gdocs_worksheet @sheetname
  end

  def show
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
        :available => AvailablePoint.course_sheet_points(course, sheet).length,
        :awarded => AwardedPoint.course_sheet_points(course, sheet).length
      }},
      :awarded => AwardedPoint.course_points(course).length,
      :available => AvailablePoint.course_points(course).length,
      :students => users.map{|u| {
        :login => u.login,
        :points => sheets.reduce({}){ |hash, sheet|
          hash.merge({ sheet => AwardedPoint.
            course_user_sheet_points(course, u, sheet).length })
          },
        :awarded => AwardedPoint.course_user_points(course, u).length
      }}
    }
  end
end
