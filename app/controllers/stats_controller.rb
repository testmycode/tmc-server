# typed: strict
# frozen_string_literal: true

# Shows the various statistics under /stats.
class StatsController < ApplicationController
  extend T::Sig
  skip_authorization_check except: [:organization_stats_index]
  before_action :set_organization

  sig { void }
  def index
    get_vars
    if @course
      add_course_breadcrumb
      add_breadcrumb 'Statistics'
      course_stats_index
    elsif @organization
      add_organization_breadcrumb
      add_breadcrumb 'Statistics'
      organization_stats_index
    else
      add_breadcrumb 'Statistics'
      general_stats_index
    end
  end

  sig { void }
  def show
    get_vars
    page = params[:id]
    if @course
      add_course_breadcrumb
      add_breadcrumb 'Stats', organization_course_stats_path
      add_breadcrumb page.humanize, organization_course_stat_path(@organization, @course, page)
      course_stats_show(page)
    else
      add_breadcrumb 'Stats', stats_path
      general_stats_show(page)
    end
  end

  private
    sig { void }
    def get_vars
      @course = Course.find(params[:course_id]) if params[:course_id]
    end

    sig { void }
    def course_stats_index
      respond_to do |format|
        format.html { render template: 'courses/stats/index' }
      end
    end

    sig { void }
    def organization_stats_index
      authorize! :view_statistics, @organization
      @stats = T.let(Stats.courses(@organization), T.nilable(T::Hash[Symbol, T.untyped]))
      respond_to do |format|
        format.html { render }
        format.json { render json: @stats, callback: params[:jsonp] }
      end
    end

    sig { void }
    def general_stats_index
      @stats = Stats.courses
      respond_to do |format|
        format.html { render }
        format.json { render json: @stats, callback: params[:jsonp] }
      end
    end

    sig { params(page: String).void }
    def course_stats_show(page)
      case page
      when 'submissions'
        course_stats_show_submissions
      when 'submission_times'
        course_stats_show_submission_times
      else
        respond_not_found('No such stats page')
      end
    end

    sig { void }
    def course_stats_show_submissions
      course = T.must(@course)
      return respond_not_found('No submissions yet') if course.submissions.empty?

      start_time =
        if params[:start_time]
        then Time.zone.parse(params[:start_time])
        else T.must(course.time_of_first_submission).to_date.in_time_zone
        end
      end_time =
        if params[:end_time]
        then Time.zone.parse(params[:end_time])
        else T.must(course.time_of_last_submission).to_date.in_time_zone
        end
      time_unit = param_as_one_of(:time_unit, [nil, 'minute', 'hour', 'day']) || 'day'
      @start_time = T.let(start_time, T.nilable(ActiveSupport::TimeWithZone))
      @end_time = T.let(end_time, T.nilable(ActiveSupport::TimeWithZone))
      @time_unit = T.let(time_unit, T.nilable(String))

      respond_to do |format|
        format.html { render template: 'courses/stats/submissions', layout: 'bare' }
        format.json do
          records = course.submissions
                          .select(['COUNT(*) c', "date_trunc('#{time_unit}', #{expr_for_time_in_time_zone('created_at')}) t"])
                          .group('t')
                          .where('created_at >= ?', start_time)
                          .where(user: User.legitimate_students)
                          .where('created_at < ?', end_time)

          date_format = '%Y-%m-%d %H:%M:%S' # query returns in this format, without timezone
          # date_format = '%FT%T.%LZ' # query returns in this format, without timezone

          lookup = {}
          for r in records
            lookup[r['t'].strftime(date_format)] = r['c'].to_i
          end
          lookup.default = 0

          result = []
          time = start_time
          while time < end_time
            result << lookup[time.strftime(date_format)]
            time += 1.send(time_unit)
          end

          render json: result
        end
      end
    end

    sig { void }
    def course_stats_show_submission_times
      course = T.must(@course)
      return respond_not_found('No submissions yet') if course.submissions.empty?

      respond_to do |format|
        format.html { render template: 'courses/stats/submission_times', layout: 'bare' }
        format.json do
          records = course.submissions.where(user: User.legitimate_students).select([
                                                                                       'COUNT(*) c',
                                                                                       "EXTRACT(HOUR FROM #{expr_for_time_in_time_zone('created_at')}) h"
                                                                                     ]).group('h').order('h ASC')

          lookup = {}
          for r in records
            lookup[r['h'].to_i] = r['c'].to_i
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

    sig { params(field: String).returns(String) }
    def expr_for_time_in_time_zone(field)
      connection = ActiveRecord::Base.connection
      "((#{field} AT TIME ZONE 'UTC') AT TIME ZONE #{connection.quote(Time.zone.name)})"
    end

    sig { params(_page: String).void }
    def general_stats_show(_page)
      respond_not_found('No such stats page')
    end

    sig { params(name: Symbol, valid_values: T::Array[T.nilable(String)]).returns(T.nilable(String)) }
    def param_as_one_of(name, valid_values)
      if valid_values.include?(params[name])
        params[name]
      else
        raise "Invalid value for parameter #{name}"
      end
    end

  private
    sig { void }
    def set_organization
      @organization = Organization.find_by(slug: params[:organization_id])
    end
end
