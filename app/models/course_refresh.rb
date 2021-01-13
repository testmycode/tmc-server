class CourseRefresh < ApplicationRecord
  belongs_to :user
  belongs_to :course_template
  has_many :course_refresh_phase_timings, dependent: :delete_all
  after_save :create_first_course_refresh_phase_timing

  private

    def create_first_course_refresh_phase_timing
        CourseRefreshPhaseTiming.create(course_refresh: self, phase_name: 'not started', time_ms: 0)
    end


end
