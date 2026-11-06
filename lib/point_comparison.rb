# typed: strict
# frozen_string_literal: true

require 'natcmp'

# Provides an ordering for AvailablePoint and AwardedPoint based on natcmp'ing their names.
module PointComparison
  extend T::Sig
  extend Comparable

  sig { params(other: T.any(AvailablePoint, AwardedPoint)).returns(Integer) }
  def <=>(other)
    T.bind(self, T.any(AvailablePoint, AwardedPoint))
    Natcmp.natcmp(name, other.name)
  end

  sig { params(a: String, b: String).returns(Integer) }
  def self.compare_point_names(a, b)
    Natcmp.natcmp(a, b)
  end

  sig { params(point_names: T::Array[String]).returns(T::Array[String]) }
  def self.sort_point_names(point_names)
    point_names.sort { |a, b| compare_point_names(a, b) }
  end
end
