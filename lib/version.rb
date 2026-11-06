# typed: strict
# frozen_string_literal: true

# Represents a version number (e.g. 1.30.5).
#
# Provides a comparison operator that handles e.g. '1.21.0 > 1.3.5'.
class Version
  extend T::Sig
  include Comparable

  sig { params(version: T.untyped).void }
  def initialize(version)
    if version.is_a?(String)
      @parts = T.let(version.split('.').map(&:to_i), T::Array[Numeric])
    elsif version.is_a?(Numeric)
      @parts = T.let([version], T::Array[Numeric])
    else
      raise "Invalid version number: #{version.inspect}"
    end
  end

  sig { returns(T::Array[Numeric]) }
  attr_reader :parts

  sig { params(other: T.untyped).returns(Integer) }
  def <=>(other)
    if other.is_a?(Version)
      p1 = parts.clone
      p2 = other.parts.clone
      p1 << 0 while p1.length < p2.length
      p2 << 0 while p2.length < p1.length
      p1.each_with_index do |n1, i|
        n2 = p2.fetch(i)
        if n1 < n2
          return -1
        elsif n1 > n2
          return 1
        end
      end
      0
    else
      raise ArgumentError, "cannot compare Version with #{other.class}"
    end
  end

  sig { returns(String) }
  def to_s
    parts.join('.')
  end
end
