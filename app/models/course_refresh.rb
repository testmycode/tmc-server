# frozen_string_literal: true

class CourseRefresh < ApplicationRecord
  belongs_to :user
  belongs_to :course_template
  has_many :course_refresh_phase_timings, dependent: :delete_all
  has_one :course_refresh_report, dependent: :destroy
  after_create :create_first_course_refresh_phase_timing

  enum status: %i[not_started in_progress complete crashed]

  def create_phase(phase_name, time_ms)
    CourseRefreshPhaseTiming.create(course_refresh: self, phase_name: phase_name, time_ms: time_ms)
  end

  private
    def create_first_course_refresh_phase_timing
      CourseRefreshPhaseTiming.create(course_refresh: self, phase_name: 'Refresh initialized', time_ms: 1)
    end
end
