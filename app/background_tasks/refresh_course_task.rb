# frozen_string_literal: true

require 'rust_langs_cli_executor'

class RefreshCourseTask
  def initialize
  end

  def run
    CourseTemplateRefresh.where(status: :not_started).each do |task|
      task.status = :in_progress
      task.save!
      courses = Course.where(course_template_id: task.course_template_id)
      Rails.logger.info("Refreshing courses created from template #{task.course_template_id}")
      rust_output = RustLangsCliExecutor.refresh(courses.first, task.id)

      ActionCable.server.broadcast("CourseTemplateRefreshChannel-course-id-#{task.course_template_id}",
        {
          message: 'Updating database',
          percent_done: 0.95,
          time: '-',
        }
      )
      courses.each do |course|
        @refresh = CourseRefreshDatabaseUpdater.new.refresh_course(course, rust_output)
      end
      ActionCable.server.broadcast("CourseTemplateRefreshChannel-course-id-#{task.course_template_id}", {
          message: 'Generating refresh report',
          percent_done: 0.99,
          time: '-',
        })
      CourseTemplateRefreshReport.create(course_template_refresh_id: task.id, refresh_errors: @refresh.errors, refresh_warnings: @refresh.warnings, refresh_notices: @refresh.notices, refresh_timings: @refresh.timings)
      ActionCable.server.broadcast("CourseTemplateRefreshChannel-course-id-#{task.course_template_id}", {
        message: 'Refresh completed',
        percent_done: 1,
        time: '-',
        course_template_refresh_id: task.id,
      })

      task.status = :complete
      task.percent_done = 1
      task.save!
    rescue => e
      Rails.logger.error("Course Refresh task #{task.id} failed:#{e}")
      Rails.logger.error(e.backtrace.join("\n"))
      CourseTemplateRefreshReport.create(course_template_refresh_id: task.id, refresh_errors: [e.backtrace.join("\n")], refresh_warnings: [], refresh_notices: [], refresh_timings: {})
      task.status = :crashed
      task.percent_done = 0
      task.create_phase(e, 0)
      task.save!
      ActionCable.server.broadcast("CourseTemplateRefreshChannel-course-id-#{task.course_template_id}", {
        message: 'Refresh crashed',
        percent_done: 0,
        time: '-',
        course_template_refresh_id: task.id,
      })
    end
  end

  def wait_delay
    5
  end
end
