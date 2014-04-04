require 'natsort'
# Shows the points summary table and exercise group-specific tables.
class PointsController < ApplicationController
  include PointsHelper
  skip_authorization_check :except => :refresh_gdocs

  def index
    @course = Course.find(params[:course_id])
    add_course_breadcrumb
    add_breadcrumb 'Points', course_points_path(@course)

    exercises = @course.exercises.select {|e| e.points_visible_to?(current_user)}
    sheets = @course.gdocs_sheets(exercises).natsort
    @summary = summary_hash(@course, exercises, sheets)
    sort_summary(@summary, params[:sort_by]) if params[:sort_by]

    respond_to do |format|
      format.html
      format.csv do
        render_csv(:filename => "#{@course.name}_points.csv")
      end
      format.json { render :json =>  @summary }
    end
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

    add_course_breadcrumb
    add_breadcrumb 'Points', course_points_path(@course)
    add_breadcrumb @sheetname, course_point_path(@course, @sheetname)

    @exercises = Exercise.course_gdocs_sheet_exercises(@course, @sheetname).sort!
    @users_to_points = AwardedPoint.per_user_in_course_with_sheet(@course, @sheetname)

    @users = User.course_sheet_students(@course, @sheetname)
    if params[:sort_by] == 'points'
      @users = @users.sort_by do |u|
        [-@users_to_points[u.login].size, u.login.downcase]
      end
    else
      @users.sort!
    end
    respond_to do |format|
      format.html
      format.json do
        output = {
          api_version: ApiVersion::API_VERSION,
          users_to_points: @users_to_points
        }
        render :json => output
      end
    end
  end

  def summary_hash(course, visible_exercises, sheets)
    per_user_and_sheet = {}
    for sheet in sheets
      AwardedPoint.count_per_user_in_course_with_sheet(course, sheet).each_pair do |username, count|
        per_user_and_sheet[username] ||= {}
        per_user_and_sheet[username][sheet] = count
      end
    end
    
    user_totals = {}
    for username, per_sheet in per_user_and_sheet
      user_totals[username] ||= 0
      user_totals[username] += per_sheet.values.reduce(0, &:+)
    end

    include_admins = current_user.administrator?
    users = User.select('login, id, administrator').where(:login => per_user_and_sheet.keys.sort_by(&:downcase)).order('login ASC')
    users = users.where(:administrator => false) unless include_admins

    {
      :sheets => sheets.map{|sheet| {
        :name => sheet,
        :total_awarded => AwardedPoint.course_sheet_points(course, sheet, include_admins).length,
        :total_available => AvailablePoint.course_sheet_points(course, sheet).length
      }},
      :total_awarded => AwardedPoint.course_points(course, include_admins).length,
      :total_available => AvailablePoint.course_points_of_exercises(course, visible_exercises).length,
      :awarded_for_user_and_sheet => per_user_and_sheet,
      :total_for_user => user_totals,
      :users => users
    }
  end
  
  def sort_summary(summary, sorting)
    if sorting == 'total_points'
      summary[:users] = summary[:users].sort_by {|user| [-summary[:total_for_user][user.login].to_i, user.login] }
    elsif sorting =~ /(.*)_points$/
      sheet = $1
      summary[:users] = summary[:users].sort_by {|user| [-summary[:awarded_for_user_and_sheet][user.login][sheet].to_i, user.login] }
    end
  end
end
