module PointComparison
  extend Comparable

  def name=(new_name)
    super
    @name_is_numeric = nil
  end

  def name_is_numeric
    @name_is_numeric ||= !!(name =~ /^\d+(?:\.\d?)?$/)
  end

  def <=>(other)
    if self.name_is_numeric && other.name_is_numeric
      self.name.to_f <=> other.name.to_f
    elsif self.name_is_numeric
      -1 # numeric ones first
    elsif other.name_is_numeric
      1
    else
      self.name <=> other.name
    end
  end
end