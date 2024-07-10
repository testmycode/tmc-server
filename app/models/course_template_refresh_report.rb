# frozen_string_literal: true

class CourseTemplateRefreshReport < ApplicationRecord
  belongs_to :course_template_refresh
  serialize :refresh_errors, class: Array, coder: JSON
  serialize :refresh_warnings, class: Array, coder: JSON
  serialize :refresh_notices, class: Array, coder: JSON
  serialize :refresh_timings, class: Hash, coder: JSON

  attr_reader :refresh_errors
  attr_reader :refresh_warnings
  attr_reader :refresh_notices
  attr_reader :refresh_timings

  def successful?
    :refresh_errors.empty?
  end
end
