# typed: strict
# frozen_string_literal: true

require 'natsort'
# Shows the points summary table and exercise group-specific tables.
class PointsController < ApplicationController
  extend T::Sig
  include PointsHelper
  before_action :set_organization

  sig { void }
  def index
    @course = Course.find(params[:course_id])
    authorize! :see_points, @course
    return respond_unauthorized('Authentication required') if current_user.guest?
    add_course_breadcrumb
    add_breadcrumb 'Points'

    if can?(:teach, @course)
      @user_fields = T.let(UserField.all.select(&:show_in_participant_list?), T.nilable(T::Array[UserField]))
    end

    only_for_user = User.find_by(login: params[:username])
    only_for_user = current_user unless can?(:teach, @course)

    if only_for_user
      exercises = @course.exercises.enabled.where(exercises: { hidden: false, hide_submission_results: false })
      sheets = @course.gdocs_sheets(exercises).natsort
      summary = summary_hash(@course, exercises, sheets, only_for_user)
      @summary = T.let(summary, T.nilable(T::Hash[Symbol, T.untyped]))
      sort_summary(summary, params[:sort_by]) if params[:sort_by]
    else
      course = @course
      summary = Rails.cache.fetch("points_#{course.id}_admin_#{current_user.administrator?}/", expires_in: 1.minute) do
        visible_exercises = course.exercises.enabled.where(exercises: { hidden: false })
        visible_exercises = visible_exercises.where(hide_submission_results: false) unless current_user.administrator?
        visible_sheets = course.gdocs_sheets(visible_exercises).natsort
        summary_hash(course, visible_exercises, visible_sheets)
      end
      @summary = summary
      sort_summary(summary, params[:sort_by]) if params[:sort_by]
    end

    respond_to do |format|
      format.html
      format.csv do
        render_csv(filename: "#{@course.name}_points.csv")
      end
      format.json { render json: @summary }
    end
  end

  sig { void }
  def show
    sheetname = T.let(params[:id], String)
    @sheetname = T.let(sheetname, T.nilable(String))
    @course = Course.find(params[:course_id])
    authorize! :see_points, @course
    return respond_unauthorized('Authentication required') if current_user.guest?

    if can?(:teach, @course)
      @user_fields = UserField.all.select(&:show_in_participant_list?)
    end

    add_course_breadcrumb
    add_breadcrumb 'Points', organization_course_points_path(@organization, @course)
    add_breadcrumb sheetname

    exercises = Exercise.course_gdocs_sheet_exercises(@course, sheetname, current_user.administrator?).includes(:available_points).order!(:name)
    @exercises = T.let(exercises, T.nilable(ActiveRecord::Relation))
    users_to_points = AwardedPoint.per_user_in_course_with_sheet(@course, sheetname, hidden: current_user.administrator?)
    @users_to_points = T.let(users_to_points, T.nilable(T::Hash[String, T::Array[String]]))

    users = @course.users.includes(:user_field_values)
    if params[:sort_by] == 'points'
      users = users.sort_by do |u|
        [-users_to_points.fetch(u.login, []).size, u.login.downcase]
      end
    else
      users.order!
    end
    users = [current_user] unless can?(:teach, @course)
    @users = T.let(users, T.nilable(T.any(ActiveRecord::Relation, T::Array[User])))
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
    sig { params(course: Course, visible_exercises: T::Enumerable[Exercise], sheets: T::Array[String], only_for_user: T.nilable(User)).returns(T::Hash[Symbol, T.untyped]) }
    def summary_hash(course, visible_exercises, sheets, only_for_user = nil)
      per_user_and_sheet = AwardedPoint.count_per_user_in_course_with_sheet(course, sheets, only_for_user, current_user.administrator?)

      user_totals = {}
      for username, per_sheet in per_user_and_sheet
        user_totals[username] ||= 0
        user_totals[username] += per_sheet.values.sum
      end

      include_admins = current_user.administrator?
      users = User.select('login, email, users.id, administrator').where(login: per_user_and_sheet.keys.sort_by(&:downcase)).includes(:organizations).includes(:user_field_values).order('login ASC')

      users = users.where(administrator: false) unless include_admins

      total_awarded = AwardedPoint.course_sheet_points(course, sheets, include_admins, only_for_user)
      total_available = AvailablePoint.course_sheet_points(course, sheets)
      {
        sheets: sheets.map do |sheet|
          {
            name: sheet,
            total_awarded: (total_awarded[sheet] || 0),
            total_available: (total_available[sheet] || 0)
          }
        end,
        total_awarded: AwardedPoint.course_points(course, include_admins, current_user.administrator?, only_for_user),
        total_available: AvailablePoint.course_points_of_exercises(course, visible_exercises),
        awarded_for_user_and_sheet: per_user_and_sheet,
        total_for_user: user_totals,
        users: users
      }
    end

    sig { params(summary: T::Hash[Symbol, T.untyped], sorting: String).void }
    def sort_summary(summary, sorting)
      if sorting == 'total_points'
        summary[:users] = summary[:users].sort_by { |user| [-summary[:total_for_user][user.login].to_i, user.login] }
      elsif sorting =~ /(.*)_points$/
        sheet = Regexp.last_match(1)
        summary[:users] = summary[:users].sort_by { |user| [-summary[:awarded_for_user_and_sheet][user.login][sheet].to_i, user.login] }
      end
    end

    sig { void }
    def set_organization
      @organization = Organization.find_by!(slug: params[:organization_id])
    end
end
