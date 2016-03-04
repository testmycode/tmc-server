require 'portable_csv'

class ParticipantsController < ApplicationController
  add_breadcrumb 'Participants', :participants_path, only: [:index, :show], if: -> { current_user.administrator? }

  def index
    authorize! :view, :participants_list
    @ordinary_fields = %w(username email)
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

    @courses = Course.order(:name).to_a
    unless params['group_completion_course_id'].blank?
      @group_completion_course = Course.find(params['group_completion_course_id'])
      @group_completion = @group_completion_course.exercise_group_completion_by_user
    end

    @participants = User.filter_by(@filter_params).order(:login)

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
    authorize! :read, @user
    @awarded_points = Hash[@user.awarded_points.to_a.sort!.group_by(&:course_id).map { |k, v| [k, v.map(&:name)] }]

    if current_user.administrator?
      add_breadcrumb @user.username, participant_path(@user)
    else
      add_breadcrumb 'My stats', participant_path(@user)
    end

    @courses = []
    @missing_points = {}
    @percent_completed = {}
    for course_id in @awarded_points.keys
      course = Course.find(course_id)
      @courses << course

      awarded = @awarded_points[course.id]
      missing = AvailablePoint.course_points(course).order!.map(&:name) - awarded
      @missing_points[course_id] = missing

      if awarded.size + missing.size > 0
        @percent_completed[course_id] = 100 * (awarded.size.to_f / (awarded.size + missing.size))
      else
        @percent_completed[course_id] = 0
      end
    end

    #@submissions = @user.submissions.order('id DESC').includes(:user)
    @submissions = @user.submissions.order('created_at DESC').includes(:user)
    Submission.eager_load_exercises(@submissions)
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
          if @visible_columns.include?(field)
            row << user.send(field)
          end
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
            percentage = sprintf('%.3f%%', (points.to_f / total.to_f) * 100)
            row << percentage
          end
        end

        csv << row
      end
    end
  end
end
