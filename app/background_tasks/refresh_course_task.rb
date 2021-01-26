# frozen_string_literal: true

require 'rust_langs_cli_executor'

class RefreshCourseTask
  def initialize
  end

  def run
    CourseRefresh.where(status: :not_started).each do |task|
      courses = Course.where(course_template_id: task.course_template_id)
      Rails.logger.info("Refreshing courses created from template #{task.course_template_id}")
      # Where to handle options for each course. i.e. only first course does directory changes
      courses.each do |course|
        Rails.logger.info("Refreshing course #{course.name}")
        rust_output = RustLangsCliExecutor.refresh(course, task.id,
          {
            no_background_operations: task.no_background_operations,
            no_directory_changes: task.no_directory_changes
          })

        refresh = CourseRefresher.new.refresh_course(course, rust_output)
        ActionCable.server.broadcast("CourseRefreshChannel-course-id-#{course.id}", {
            message: 'Generating refresh report',
            percent_done: 0.99,
            time: '-',
          })
        CourseRefreshReport.create(course_refresh_id: task.id, refresh_errors: refresh.errors, refresh_warnings: refresh.warnings, refresh_notices: refresh.notices, refresh_timings: refresh.timings)
        ActionCable.server.broadcast("CourseRefreshChannel-course-id-#{course.id}", {
          message: 'Refresh completed',
          percent_done: 1,
          time: '-',
          course_refresh_id: task.id,
        })
      end
      task.status = :complete
      task.percent_done = 1
      task.save!
    rescue => e
      Rails.logger.error("Course Refresh task #{task.id} failed: #{e}")
      Rails.logger.error(e.backtrace.join("\n"))
      # generate error report here for task
      task.status = :crashed
      task.percent_done = 0
      task.create_phase(e, 0)
      task.save!
    end
  end

  def wait_delay
    5
  end
end
