module PointsHelper
  def x_if_point_awarded(points, point_name)
    if point_awarded?(points, point_name)
      return "x"
    else
      return ""
    end
  end

  def point_awarded?(points, point_name)
    points.index{|p| p.name == point_name}
  end
end
