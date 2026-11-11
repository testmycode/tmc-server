# typed: strict
# frozen_string_literal: true

class CourseTemplateRefreshReport < ApplicationRecord
  extend T::Sig
  belongs_to :course_template_refresh
  serialize :refresh_errors, class: Array, coder: JSON
  serialize :refresh_warnings, class: Array, coder: JSON
  serialize :refresh_notices, class: Array, coder: JSON
  serialize :refresh_timings, class: Hash, coder: JSON

  sig { returns(T::Boolean) }
  def successful?
    refresh_errors.blank?
  end
end
