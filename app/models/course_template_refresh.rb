# typed: strict
# frozen_string_literal: true

class CourseTemplateRefresh < ApplicationRecord
  extend T::Sig
  belongs_to :user, optional: true
  belongs_to :course_template
  has_many :course_template_refresh_phases, dependent: :delete_all
  has_one :course_template_refresh_report, dependent: :destroy
  after_create :create_first_course_template_refresh_phase

  enum :status, { not_started: 0, in_progress: 1, complete: 2, crashed: 3 }

  sig { params(phase_name: T.untyped, time_ms: T.untyped).returns(CourseTemplateRefreshPhase) }
  def create_phase(phase_name, time_ms)
    CourseTemplateRefreshPhase.create(course_template_refresh: self, phase_name: phase_name, time_ms: time_ms)
  end

  private
    sig { void }
    def create_first_course_template_refresh_phase
      CourseTemplateRefreshPhase.create(course_template_refresh: self, phase_name: 'Refresh initialized', time_ms: 0)
    end
end
