# Shows the various statistics under /stats.
class StatsController < ApplicationController
  skip_authorization_check

  def index
    get_vars
    if @course
      add_course_breadcrumb
      add_breadcrumb 'Stats', course_stats_path(@course)
      course_stats_index
    else
      add_breadcrumb 'Stats', stats_path
      general_stats_index
    end
  end

  def show
    get_vars
    page = params[:id]
    if @course
      add_course_breadcrumb
      add_breadcrumb 'Stats', course_stats_path(@course)
      add_breadcrumb page.humanize, course_stat_path(@course, page)
      course_stats_show(page)
    else
      add_breadcrumb 'Stats', stats_path
      general_stats_show(page)
    end
  end

private
  def get_vars
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
  end

  def course_stats_index
    respond_to do |format|
      format.html { render template: 'courses/stats/index' }
    end
  end

  def general_stats_index
    @stats = Stats.all
    respond_to do |format|
      format.html { render }
      format.json { render json: @stats, callback: params[:jsonp] }
    end
  end

  def course_stats_show(page)
    case page
    when 'submissions'
      course_stats_show_submissions
    when 'submission_times'
      course_stats_show_submission_times
    else
      respond_not_found("No such stats page")
    end
  end

  def course_stats_show_submissions
    return respond_not_found("No submissions yet") if @course.submissions.empty?

    @start_time =
      if params[:start_time]
      then Time.zone.parse(params[:start_time])
      else @course.time_of_first_submission.to_date.in_time_zone
      end
    @end_time =
      if params[:end_time]
      then Time.zone.parse(params[:end_time])
      else @course.time_of_last_submission.to_date.in_time_zone
      end
    @time_unit = param_as_one_of(:time_unit, [nil, 'minute', 'hour', 'day'])
    @time_unit = 'day' if @time_unit == nil

    respond_to do |format|
      format.html { render template: 'courses/stats/submissions', layout: 'bare' }
      format.json do

        records =
          @course.submissions.
            select(['COUNT(*) c', "date_trunc('#{@time_unit}', #{expr_for_time_in_time_zone('created_at')}) t"]).
            group('t').
            where('created_at >= ?', @start_time).
            where(user: User.legitimate_students).
            where('created_at < ?', @end_time)

        date_format = "%Y-%m-%d %H:%M:%S" # query returns in this format, without timezone

        lookup = {}
        for r in records
          lookup[r.t] = r.c.to_i
        end
        lookup.default = 0

        result = []
        time = @start_time
        while time < @end_time
          result << lookup[time.strftime(date_format)]
          time += 1.send(@time_unit)
        end

        render json: result
      end
    end
  end

  def course_stats_show_submission_times
    return respond_not_found("No submissions yet") if @course.submissions.empty?

    respond_to do |format|
      format.html { render template: 'courses/stats/submission_times', layout: 'bare' }
      format.json do
        records = @course.submissions.where(user: User.legitimate_students).select([
          'COUNT(*) c',
          "EXTRACT(HOUR FROM #{expr_for_time_in_time_zone('created_at')}) h"
        ]).group('h').order('h ASC')

        lookup = {}
        for r in records
          lookup[r.h.to_i] = r.c.to_i
        end
        lookup.default = 0

        result = []
        for h in 0..23
          result << lookup[h]
        end

        render json: result
      end
    end
  end

  def expr_for_time_in_time_zone(field)
    connection = ActiveRecord::Base.connection
    "((#{field} AT TIME ZONE 'UTC') AT TIME ZONE #{connection.quote(Time.zone.name)})"
  end

  def general_stats_show(page)
    respond_not_found("No such stats page")
  end

  def param_as_one_of(name, valid_values)
    if valid_values.include?(params[name])
      params[name]
    else
      raise "Invalid value for parameter #{name}"
    end
  end
end
