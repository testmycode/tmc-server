# frozen_string_literal: true.
module PointVisualisation
  extend ActiveSupport::Concern

  def define_point_stats(user)
    # TODO: bit ugly
    @awarded_points = Hash[AwardedPoint.where(id: AwardedPoint.all_awarded(user)).to_a.sort!.group_by(&:course_id).map { |k, v| [k, v.map(&:name)] }]
    @courses = []
    @missing_points = {}
    @percent_completed = {}
    @group_completion_ratios = {}
    @awarded_points.keys.each do |course_id|
      course = Course.find(course_id)
      next if course.hide_submissions?
      @courses << course

      awarded = @awarded_points[course.id]
      missing = AvailablePoint.course_points(course).order!.map(&:name) - awarded
      @missing_points[course_id] = missing

      @percent_completed[course_id] =
        if (awarded.size + missing.size).positive?
          100 * (awarded.size.to_f / (awarded.size + missing.size))
        else
          0
        end
      @group_completion_ratios[course_id] = course.exercise_group_completion_ratio_for_user(user)
    end
  end
end
