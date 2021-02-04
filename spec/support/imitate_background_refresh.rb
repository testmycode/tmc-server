# frozen_string_literal: true

class ImitateBackgroundRefresh
  def refresh(course_template, user)
    # Find all courses where ctid matches
    courses = Course.where(course_template_id: course_template.id)
    # Generate a dummy CourseTemplateRefreshReport, that is given to RustLangsCliExecutor for updating progress
    refresh = courses.first.refresh(user.id)
    # Pass first course, that does the directory changes
    data = RustLangsCliExecutor.refresh(courses.first, refresh.id)
    # Update database for each course on returned data
    courses.each do |course|
      CourseRefreshDatabaseUpdater.new.refresh_course(course, data)
    end
    # Increment cached version for course_template, (rust-langs increments the same way)
    courses.first.increment_cached_version
    courses.first.course_template.save!
    course_template.reload
    courses.each(&:save!)
  end
end
