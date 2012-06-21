class Version
  include Comparable

  def initialize(version)
    if version.is_a?(String)
      @parts = version.split('.').map(&:to_i)
    elsif version.is_a?(Numeric)
      @parts = [version]
    else
      raise "Invalid version number: #{version.inspect}"
    end
  end

  attr_reader :parts

  def <=>(other)
    if other.is_a?(Version)
      p1 = self.parts.clone
      p2 = other.parts.clone
      p1 << 0 while p1.length < p2.length
      p2 << 0 while p2.length < p1.length
      for n1, n2 in p1.zip(p2)
        if n1 < n2
          return -1
        elsif n1 > n2
          return 1
        end
      end
      0
    else
      raise ArgumentError.new("cannot compare Version with #{other.class}")
    end
  end

  def to_s
    parts.join('.')
  end
end