class AvailablePointList
  def available_point_list(available_points)
    available_points.map { |ap| available_point_data(ap) }
  end

  def available_point_data(available_point)
    {
        id: available_point.id,
        name: available_point.name,
        exercise_id: available_point.exercise_id,
        requires_review: available_point.requires_review
    }
  end
end
