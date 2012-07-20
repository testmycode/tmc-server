class StatsController < ApplicationController
  skip_authorization_check
  
  def index
    get_vars
    if @course
      course_stats_index
    else
      general_stats_index
    end
  end

  def show
    get_vars
    page = params[:id]
    if @course
      course_stats_show(page)
    else
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
      format.html { render :template => 'courses/stats/index' }
    end
  end

  def general_stats_index
    @stats = Stats.all
    respond_to do |format|
      format.html { render }
      format.json { render :json => @stats, :callback => params[:jsonp] }
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
      then Time.parse(params[:start_time])
      else @course.time_of_first_submission.to_date.to_time
      end
    @end_time =
      if params[:end_time]
      then Time.parse(params[:end_time])
      else @course.time_of_last_submission.to_date.to_time
      end
    @time_unit = param_as_one_of(:time_unit, [nil, 'minute', 'hour', 'day'])
    @time_unit = 'day' if @time_unit == nil

    respond_to do |format|
      format.html { render :template => 'courses/stats/submissions', :layout => 'bare' }
      format.json do

        records =
          @course.submissions.
            select(['COUNT(*) c', "date_trunc('#{@time_unit}', created_at) t"]).
            group('t').
            where('created_at >= ?', @start_time).
            where('created_at < ?', @end_time).
            limit(100000) # for some security

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

        render :json => result
      end
    end
  end

  def course_stats_show_submission_times
    return respond_not_found("No submissions yet") if @course.submissions.empty?

    respond_to do |format|
      format.html { render :template => 'courses/stats/submission_times', :layout => 'bare' }
      format.json do
        records = @course.submissions.select(['COUNT(*) c', "EXTRACT(HOUR FROM created_at) h"]).group('h').order('h ASC')

        lookup = {}
        for r in records
          lookup[r.h.to_i] = r.c.to_i
        end
        lookup.default = 0

        result = []
        for h in 0..23
          result << lookup[h]
        end

        render :json => result
      end
    end
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
