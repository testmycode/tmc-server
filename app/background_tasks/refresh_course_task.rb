# frozen_string_literal: true

require 'rust_langs_cli_executor'

class RefreshCourseTask
  def initialize
  end

  def run
    CourseRefresh.all.each do |task|
      finished_successfully = false
      begin
        courses = Course.where(course_template_id: task.course_template_id)
        Rails.logger.info("Refreshing courses created from template #{task.course_template_id}")
        courses.each do |course|
          Rails.logger.info("Refreshing course #{course.name}")
          RustLangsCliExecutor.refresh(course, task.id, task.no_background_operations, task.no_directory_changes)
          finished_successfully = true
        end
      rescue => e
        Rails.logger.error("Task failed: #{e}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
      task.destroy! if finished_successfully
    end
  end

  def wait_delay
    5
  end
end
