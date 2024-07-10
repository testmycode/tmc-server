# frozen_string_literal: true

require 'rust_langs_cli_executor'
require 'fileutils'
require 'course_refresh_database_updater'

class RefreshCourseTask
  def initialize
  end

  def run
    CourseTemplateRefresh.where(status: :not_started).each do |task|
      channel_id = task.course_template_id
      task.status = :in_progress
      task.save!
      ActionCable.server.broadcast("CourseTemplateRefreshChannel-#{channel_id}", { refresh_initialized: true })

      courses = Course.where(course_template_id: task.course_template_id)
      Rails.logger.info("Refreshing courses created from template #{task.course_template_id}")

      rust_output = RustLangsCliExecutor.refresh(task)
      task.langs_refresh_output = rust_output

      broadcast_to_channel(channel_id, 'Updating database', 0.95, '-')
      # Should we do this loop in CourseRefreshDatabaseUpdater?
      courses.each do |course|
        @refresh = CourseRefreshDatabaseUpdater.new.refresh_course(course, rust_output)
      end

      broadcast_to_channel(channel_id, 'Generating refresh report', 0.98, '-')
      CourseTemplateRefreshReport.create(course_template_refresh_id: task.id, refresh_errors: @refresh.errors, refresh_warnings: @refresh.warnings, refresh_notices: @refresh.notices, refresh_timings: @refresh.timings)

      broadcast_to_channel(channel_id, 'Cleaning up cache', 0.99, '-')
      if File.directory?(task.langs_refresh_output['output-data']['new-cache-path'])
        old_cache_path = task.course_template.cache_path
        task.course_template.increment_cached_version
        task.course_template.save!
        task.course_template.reload
        courses.each(&:save!)
        FileUtils.rm_rf(old_cache_path)
      end

      broadcast_to_channel(channel_id, 'Refresh completed', 1, '-', task.id)
      task.status = :complete
      task.percent_done = 1
      task.save!
    rescue => e
      Rails.logger.error("Course Refresh task #{task.id} failed:#{e}")
      Rails.logger.error(e.backtrace.join("\n"))
      CourseTemplateRefreshReport.create(course_template_refresh_id: task.id, refresh_errors: [e.backtrace.join("\n")], refresh_warnings: [], refresh_notices: [], refresh_timings: {})
      broadcast_to_channel(channel_id, 'Refresh crashed', 0, '-', task.id)

      task.status = :crashed
      task.percent_done = 0
      task.create_phase(e, 0)
      task.save!
    end
  end

  def wait_delay
    5
  end

  private
    def broadcast_to_channel(id, msg, percent, time, refresh_id = nil)
      ActionCable.server.broadcast("CourseTemplateRefreshChannel-#{id}", {
        message: msg,
        percent_done: percent,
        time: time,
        course_template_refresh_id: refresh_id,
      })
    end
end
