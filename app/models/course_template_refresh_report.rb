# frozen_string_literal: true

class CourseTemplateRefreshReport < ApplicationRecord
  belongs_to :course_template_refresh
  serialize :refresh_errors, Array
  serialize :refresh_warnings, Array
  serialize :refresh_notices, Array
  serialize :refresh_timings, Hash

  attr_reader :refresh_errors
  attr_reader :refresh_warnings
  attr_reader :refresh_notices
  attr_reader :refresh_timings

  def successful?
    :refresh_errors.empty?
  end
end
