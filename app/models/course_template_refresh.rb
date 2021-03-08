# frozen_string_literal: true

class CourseTemplateRefresh < ApplicationRecord
  belongs_to :user
  belongs_to :course_template
  has_many :course_template_refresh_phases, dependent: :delete_all
  has_one :course_template_refresh_report, dependent: :destroy
  after_create :create_first_course_template_refresh_phase

  enum status: %i[not_started in_progress complete crashed]

  def create_phase(phase_name, time_ms)
    CourseTemplateRefreshPhase.create(course_template_refresh: self, phase_name: phase_name, time_ms: time_ms)
  end

  private
    def create_first_course_template_refresh_phase
      CourseTemplateRefreshPhase.create(course_template_refresh: self, phase_name: 'Refresh initialized', time_ms: 0)
    end
end
