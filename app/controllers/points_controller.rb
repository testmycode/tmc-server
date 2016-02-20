require 'natsort'
# Shows the points summary table and exercise group-specific tables.
class PointsController < ApplicationController
  include PointsHelper
  before_action :set_organization

  def index
    @course = Course.find(params[:course_id])
    authorize! :see_points, @course
    add_course_breadcrumb
    add_breadcrumb 'Points'

    only_for_user = User.find_by(login: params[:username])

    if only_for_user
        exercises = @course.exercises.where(exercises: {hidden: false})
        sheets = @course.gdocs_sheets(exercises).natsort
        @summary = summary_hash(@course, exercises, sheets, only_for_user)
        sort_summary(@summary, params[:sort_by]) if params[:sort_by]
        @summary
    else
      Rails.cache.fetch("points_#{@course.id}_admin_#{current_user.administrator?}/", expires_in: 1.minutes) do
        exercises = @course.exercises.where(exercises: {hidden: false})
        #exercises = @course.exercises.select { |e| e.points_visible_to?(current_user) }
        sheets = @course.gdocs_sheets(exercises).natsort
        @summary = summary_hash(@course, exercises, sheets)
        sort_summary(@summary, params[:sort_by]) if params[:sort_by]

        expires_in 1.minutes, :public => true

        @summary
      end
    end


    respond_to do |format|
      format.html
      format.csv do
        render_csv(filename: "#{@course.name}_points.csv")
      end
      format.json { render json: @summary }
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
    authorize! :see_points, @course
    show_timestamps = !!params[:timestamps]

    add_course_breadcrumb
    add_breadcrumb 'Points', organization_course_points_path(@organization, @course)
    add_breadcrumb @sheetname

    @exercises = Exercise.course_gdocs_sheet_exercises(@course, @sheetname).order!
    @users_to_points = AwardedPoint.per_user_in_course_with_sheet(@course, @sheetname, {show_timestamps: show_timestamps})

    @users = User.course_sheet_students(@course, @sheetname)
    if params[:sort_by] == 'points'
      @users = @users.sort_by do |u|
        [-@users_to_points[u.login].size, u.login.downcase]
      end
    else
      @users.order!
    end
    respond_to do |format|
      format.html
      format.json do
        output = {
          api_version: ApiVersion::API_VERSION,
          users_to_points: @users_to_points
        }
        render json: output
      end
    end
  end

  private

  def summary_hash(course, visible_exercises, sheets, only_for_user = nil)
    per_user_and_sheet = AwardedPoint.count_per_user_in_course_with_sheet(course, sheets, only_for_user)

    user_totals = {}
    for username, per_sheet in per_user_and_sheet
      user_totals[username] ||= 0
      user_totals[username] += per_sheet.values.reduce(0, &:+)
    end

    include_admins = current_user.administrator?
    users = User.select('login, id, administrator').where(login: per_user_and_sheet.keys.sort_by(&:downcase)).order('login ASC')

    users = users.where(administrator: false) unless include_admins

    total_awarded = AwardedPoint.course_sheet_points(course, sheets, include_admins)
    total_available = AvailablePoint.course_sheet_points(course, sheets)
    {
      sheets: sheets.map do |sheet|
        {
          name: sheet,
          total_awarded: total_awarded[sheet],
          total_available: total_available[sheet]
        }
      end,
      total_awarded: AwardedPoint.course_points(course, include_admins),
      total_available: AvailablePoint.course_points_of_exercises(course, visible_exercises),
      awarded_for_user_and_sheet: per_user_and_sheet,
      total_for_user: user_totals,
      users: users
    }
  end

  def sort_summary(summary, sorting)
    if sorting == 'total_points'
      summary[:users] = summary[:users].sort_by { |user| [-summary[:total_for_user][user.login].to_i, user.login] }
    elsif sorting =~ /(.*)_points$/
      sheet = $1
      summary[:users] = summary[:users].sort_by { |user| [-summary[:awarded_for_user_and_sheet][user.login][sheet].to_i, user.login] }
    end
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end
end
