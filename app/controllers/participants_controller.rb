# frozen_string_literal: true

require 'portable_csv'

class ParticipantsController < ApplicationController
  before_action :set_organization, only: [:index]

  def index
    if @organization.nil?
      authorize! :view, :participants_list
      courses = Course.all
      users = User.all
    else
      authorize! :view_participant_list, @organization
      add_organization_breadcrumb
      courses = Course.where(organization: @organization)
      users = User.organization_students(@organization)
    end
    add_breadcrumb 'Participants'

    @ordinary_fields = %w[username email]
    @extra_fields = UserField.all
    valid_fields = @ordinary_fields + @extra_fields.map(&:name) + ['include_administrators']

    @filter_params = params_starting_with('filter_', valid_fields, remove_prefix: true)
    @raw_filter_params = params_starting_with('filter_', valid_fields, remove_prefix: false)

    @column_params = params_starting_with('column_', valid_fields, remove_prefix: true)
    @raw_column_params = params_starting_with('column_', valid_fields, remove_prefix: false)
    @visible_columns =
      if @column_params.empty?
        @ordinary_fields + @extra_fields.select(&:show_in_participant_list?).map(&:name)
      else
        @column_params.keys
      end

    @courses = courses.order(:name).to_a

    if params['group_completion_course_id'].present?
      @group_completion_course = courses.find(params['group_completion_course_id'])
      @group_completion = @group_completion_course.exercise_group_completion_by_user
    end

    @participants = users.filter_by(@filter_params).order(:login)

    if @group_completion && params['show_with_no_points'].blank?
      @participants = @participants.includes(:awarded_points).to_a.select do |user|
        user.awarded_points.to_a.any? { |ap| ap.course_id == @group_completion_course.id }
      end
    end

    respond_to do |format|
      format.html
      format.json do
        render json: index_json_data
      end
      format.csv do
        render_csv(text: index_csv, filename: 'participants.csv')
      end
    end
  end

  def show
    @user = User.find(params[:id])
    authorize! :view_participant_information, @user
    # TODO: bit ugly -- and now it's even worse!
    @awarded_points = Hash[
      AwardedPoint.where(id: AwardedPoint.all_awarded(@user))
                  .to_a
                  .sort!
                  .group_by(&:course_id).map do |id, course_points|
        [id, {
          awarded: course_points.reject(&:awarded_after_soft_deadline?).map(&:name),
          late: course_points.select(&:awarded_after_soft_deadline?).map(&:name)
        }]
      end
  ]

    if current_user.administrator?
      add_breadcrumb 'Participants', :participants_path
      add_breadcrumb @user.username, participant_path(@user)
      @app_data = JSON.pretty_generate(JSON.parse(@user.user_app_data.to_json))
    else
      add_breadcrumb 'My stats', participant_path(@user)
    end

    @courses = []
    @missing_points = {}
    @percent_completed = {}
    @group_completion_counts = {}
    @group_available_points = {}
    for course_id in @awarded_points.keys
      course = Course.find(course_id)
      next if course.hide_submissions?
      @courses << course

      awarded = @awarded_points[course.id]
      missing = AvailablePoint.course_points(course).order!.map(&:name) - awarded[:awarded] - awarded[:late]
      @missing_points[course_id] = missing

      @percent_completed[course_id] = if awarded[:awarded].size + awarded[:late].size + missing.size > 0
        100 * ((awarded[:awarded].size.to_f + awarded[:late].size.to_f * course.soft_deadline_point_multiplier) / (awarded[:awarded].size + awarded[:late].size + missing.size))
      else
        0
      end
      @group_completion_counts[course_id] = course.exercise_group_completion_counts_for_user(@user)
    end

    @submissions = if current_user.administrator? || current_user.id == @user.id
      @user.submissions.order('created_at DESC').includes(:user).includes(:course)
    else # teacher and assistant sees only submissions for own teacherd courses
      @user.submissions.order('created_at DESC').includes(:user, :course).where(course: current_user.teaching_in_courses)
    end
    @submission_count = @submissions.count
    @submissions = @submissions.limit(100) unless !!params[:view_all]

    Submission.eager_load_exercises(@submissions)
  end

  def me
    authorize! :view_participant_information, current_user
    redirect_to participant_path(current_user)
  end

  def password_reset_link
    @user = User.find(params[:id])
    authorize! :view_participant_information, @user
    return respond_forbidden('This feature is disabled for admin accounts') if @user.administrator?

    @password_reset_link = @user.generate_password_reset_link
  end

  private

    def index_json_data
      result = []
      @participants.each do |user|
        record = { id: user.id, username: user.login, email: user.email }
        @extra_fields.each do |field|
          if @visible_columns.include?(field.name)
            record[field.name] = user.field_ruby_value(field)
          end
        end

        if @group_completion
          record[:groups] = {}
          for group, group_data in @group_completion
            record[:groups][group] = {
              points: group_data[:points_by_user][user.id] || 0,
              total: group_data[:available_points]
            }
          end
        end

        result << record
      end

      {
        api_version: ApiVersion::API_VERSION,
        participants: result
      }
    end

    def index_csv
      PortableCSV.generate(force_quotes: true) do |csv|
        title_row = (@ordinary_fields + @extra_fields.map(&:name)).select { |f| @visible_columns.include?(f) }.map(&:humanize)

        if @group_completion
          completion_cols = @group_completion.keys.sort { |a, b| Natcmp.natcmp(a, b) }
          title_row += completion_cols
        end

        csv << title_row

        @participants.each do |user|
          row = []
          for field in @ordinary_fields
            row << user.send(field) if @visible_columns.include?(field)
          end
          for field in @extra_fields
            if @visible_columns.include?(field.name)
              row << user.field_ruby_value(field)
            end
          end

          if @group_completion
            for group in completion_cols
              group_data = @group_completion[group]
              points = group_data[:points_by_user][user.id] || 0
              total = group_data[:available_points]
              percentage = format('%.3f%%', (points.to_f / total.to_f) * 100)
              row << percentage
            end
          end

          csv << row
        end
      end
    end

  private

    def set_organization
      @organization = Organization.find_by(slug: params[:organization_id]) unless params[:organization_id].nil?
    end
end
