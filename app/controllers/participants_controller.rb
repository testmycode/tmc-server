# typed: strict
# frozen_string_literal: true

require 'csv'
require 'natcmp'

class ParticipantsController < ApplicationController
  extend T::Sig
  before_action :set_organization, only: [:index]

  sig { void }
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

    ordinary_fields = %w[username email]
    extra_fields = UserField.all
    @ordinary_fields = T.let(ordinary_fields, T.nilable(T::Array[String]))
    @extra_fields = T.let(extra_fields, T.nilable(T::Array[UserField]))
    valid_fields = ordinary_fields + extra_fields.map(&:name) + ['include_administrators']

    filter_params = params_starting_with('filter_', valid_fields, remove_prefix: true)
    @filter_params = T.let(filter_params, T.nilable(T::Hash[String, T.untyped]))
    @raw_filter_params = T.let(params_starting_with('filter_', valid_fields, remove_prefix: false), T.nilable(T::Hash[String, T.untyped]))

    column_params = params_starting_with('column_', valid_fields, remove_prefix: true)
    @column_params = T.let(column_params, T.nilable(T::Hash[String, T.untyped]))
    @raw_column_params = T.let(params_starting_with('column_', valid_fields, remove_prefix: false), T.nilable(T::Hash[String, T.untyped]))
    visible_columns =
      if column_params.empty?
        ordinary_fields + extra_fields.filter_map { |field| field.name if field.show_in_participant_list? }
      else
        column_params.keys
      end
    @visible_columns = T.let(visible_columns, T.nilable(T::Array[String]))

    @courses = T.let(courses.order(:name).to_a, T.nilable(T::Array[Course]))

    group_completion_course = T.let(nil, T.nilable(Course))
    group_completion = T.let(nil, T.nilable(T::Hash[String, T::Hash[Symbol, T.untyped]]))
    if params['group_completion_course_id'].present?
      group_completion_course = courses.find(params['group_completion_course_id'])
      group_completion = group_completion_course.exercise_group_completion_by_user
    end
    @group_completion_course = T.let(group_completion_course, T.nilable(Course))
    @group_completion = T.let(group_completion, T.nilable(T::Hash[String, T::Hash[Symbol, T.untyped]]))

    # filter_by is a User class method, which relations delegate to.
    participants = T.unsafe(users).filter_by(filter_params).order(:login)

    if group_completion_course && params['show_with_no_points'].blank?
      participants = participants.includes(:awarded_points).to_a.select do |user|
        user.awarded_points.to_a.any? { |ap| ap.course_id == group_completion_course.id }
      end
    end
    @participants = T.let(participants, T.nilable(T.any(ActiveRecord::Relation, T::Array[User])))

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

  sig { void }
  def show
    user = User.find(params[:id])
    @user = T.let(user, T.nilable(User))
    authorize! :view_participant_information, user
    # TODO: bit ugly -- and now it's even worse!
    awarded_points =
      AwardedPoint.where(id: AwardedPoint.all_awarded(user))
                  .to_a
                  .sort!
                  .group_by(&:course_id).transform_values do |course_points|
        late, on_time = course_points.partition(&:awarded_after_soft_deadline?)
        { awarded: on_time.map(&:name), late: late.map(&:name) }
      end
    @awarded_points = T.let(awarded_points, T.nilable(T::Hash[T.nilable(Integer), { awarded: T::Array[String], late: T::Array[String] }]))

    if current_user.administrator?
      add_breadcrumb 'Participants', :participants_path
      add_breadcrumb user.username, participant_path(user)
      @app_data = T.let(JSON.pretty_generate(JSON.parse(user.user_app_data.to_json)), T.nilable(String))
      courses_mooc_fi_status = user.courses_mooc_fi_migration_status
      @courses_mooc_fi_status = T.let(courses_mooc_fi_status, T.nilable(T::Hash[Symbol, T.untyped]))
      @courses_mooc_fi_status_label = T.let(courses_mooc_fi_status_label(user, courses_mooc_fi_status), T.nilable(String))
      @courses_mooc_fi_force_migrate_available = T.let(!user.managed_externally? || courses_mooc_fi_account_missing?(courses_mooc_fi_status), T.nilable(T::Boolean))
    else
      add_breadcrumb 'My stats', participant_path(user)
    end

    courses = T.let([], T::Array[Course])
    missing_points = T.let({}, T::Hash[T.nilable(Integer), T::Array[String]])
    percent_completed = T.let({}, T::Hash[T.nilable(Integer), Numeric])
    group_completion_counts = T.let({}, T::Hash[T.nilable(Integer), T::Hash[String, T::Hash[Symbol, Numeric]]])
    @courses = courses
    @missing_points = T.let(missing_points, T.nilable(T::Hash[T.nilable(Integer), T::Array[String]]))
    @percent_completed = T.let(percent_completed, T.nilable(T::Hash[T.nilable(Integer), Numeric]))
    @group_completion_counts = T.let(group_completion_counts, T.nilable(T::Hash[T.nilable(Integer), T::Hash[String, T::Hash[Symbol, Numeric]]]))
    @group_available_points = T.let({}, T.nilable(T::Hash[T.untyped, T.untyped]))
    for course_id in awarded_points.keys
      course = Course.find(course_id)
      next if course.hide_submissions?
      courses << course

      awarded = T.must(awarded_points[course.id])
      missing = AvailablePoint.course_points(course).order!.map(&:name) - awarded[:awarded] - awarded[:late]
      missing_points[course_id] = missing

      percent_completed[course_id] = if awarded[:awarded].size + awarded[:late].size + missing.size > 0
        100 * ((awarded[:awarded].size.to_f + (awarded[:late].size.to_f * course.soft_deadline_point_multiplier)) / (awarded[:awarded].size + awarded[:late].size + missing.size))
      else
        0
      end
      group_completion_counts[course_id] = course.exercise_group_completion_counts_for_user(user)
    end

    submissions = if current_user.administrator? || current_user.id == user.id
      user.submissions.order('created_at DESC').includes(:user).includes(:course)
    else # teacher and assistant sees only submissions for own teacherd courses
      user.submissions.order('created_at DESC').includes(:user, :course).where(course: current_user.teaching_in_courses)
    end
    @submission_count = T.let(submissions.count, T.nilable(Integer))
    submissions = submissions.limit(100) unless !!params[:view_all]
    @submissions = T.let(submissions, T.nilable(ActiveRecord::Relation))

    Submission.eager_load_exercises(submissions)
  end

  sig { void }
  def me
    authorize! :view_participant_information, current_user
    redirect_to participant_path(current_user)
  end

  sig { void }
  def password_reset_link
    @user = User.find(params[:id])
    authorize! :view_participant_information, @user
    return respond_forbidden('This feature is disabled for admin accounts') if @user.administrator?

    @password_reset_link = T.let(@user.generate_password_reset_link, T.nilable(String))
  end

  sig { void }
  def force_migrate_to_courses_mooc_fi
    @user = User.find(params[:id])
    authorize! :view_participant_information, @user
    return respond_forbidden('This feature is only available to admins') unless current_user.administrator?
    return respond_forbidden('This feature is disabled for admin accounts') if @user.administrator?

    if @user.managed_externally? && !courses_mooc_fi_account_missing?(@user.courses_mooc_fi_migration_status)
      return redirect_to participant_path(@user), alert: 'User is already managed by courses.mooc.fi.'
    end

    result = @user.force_migrate_to_courses_mooc_fi
    if result[:success]
      redirect_to participant_path(@user), notice:
        "User force-migrated to courses.mooc.fi (id: #{result[:courses_mooc_fi_user_id]}). " \
        "They have no password yet — use 'Generate password reset link' below to give them one."
    else
      redirect_to participant_path(@user), alert: "Force migration to courses.mooc.fi failed: #{result[:error]}"
    end
  end

  private
    # nil means the live status is unknown (unreachable/unconfigured) -- trust the local flag
    # instead of treating the account as missing.
    sig { params(status: T.nilable(T::Hash[Symbol, T.untyped])).returns(T::Boolean) }
    def courses_mooc_fi_account_missing?(status)
      status.present? && (!status[:shadow_user_exists] || status[:deleted_at].present?)
    end

    sig { params(user: User, status: T.nilable(T::Hash[Symbol, T.untyped])).returns(String) }
    def courses_mooc_fi_status_label(user, status)
      return 'Broken: flagged as migrated locally but missing the target id' if user.externally_managed_without_target?
      if user.managed_externally?
        return "Broken: flagged as migrated locally, but courses.mooc.fi doesn't have a live account for this user" if courses_mooc_fi_account_missing?(status)
        return 'Fully migrated'
      end
      return 'Inconsistent: courses.mooc.fi already has a password, but it isn\'t linked locally' if status&.dig(:password_set)

      'Not migrated'
    end
    sig { returns(T::Hash[Symbol, T.untyped]) }
    def index_json_data
      visible_columns = T.must(@visible_columns)
      result = []
      T.must(@participants).each do |user|
        record = T.let({ id: user.id, username: user.login, email: user.email }, T::Hash[T.any(Symbol, String), T.untyped])
        T.must(@extra_fields).each do |field|
          if visible_columns.include?(field.name)
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

    sig { returns(String) }
    def index_csv
      ordinary_fields = T.must(@ordinary_fields)
      extra_fields = T.must(@extra_fields)
      visible_columns = T.must(@visible_columns)
      group_completion = @group_completion
      CSV.generate(force_quotes: true) do |csv|
        title_row = (ordinary_fields + extra_fields.map(&:name)).filter_map { |f| f.humanize if visible_columns.include?(f) }

        completion_cols = T.let([], T::Array[String])
        if group_completion
          completion_cols = group_completion.keys.sort { |a, b| Natcmp.natcmp(a, b) }
          title_row += completion_cols
        end

        csv << title_row

        T.must(@participants).each do |user|
          row = []
          for field in ordinary_fields
            row << user.send(field) if visible_columns.include?(field)
          end
          for field in extra_fields
            if visible_columns.include?(field.name)
              row << user.field_ruby_value(field)
            end
          end

          if group_completion
            for group in completion_cols
              group_data = T.must(group_completion[group])
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

    sig { void }
    def set_organization
      @organization = Organization.find_by!(slug: params[:organization_id]) unless params[:organization_id].nil?
    end
end
