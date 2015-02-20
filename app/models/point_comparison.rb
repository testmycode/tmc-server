require 'natcmp'

# Provides an ordering for AvailablePoint and AwardedPoint based on natcmp'ing their names.
module PointComparison
  extend Comparable

  def <=>(other)
    Natcmp.natcmp(name, other.name)
  end

  def self.compare_point_names(a, b)
    Natcmp.natcmp(a, b)
  end

  def self.sort_point_names(point_names)
    point_names.sort { |a, b| compare_point_names(a, b) }
  end
end
