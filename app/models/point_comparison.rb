module PointComparison
  extend Comparable
  
  def <=>(other)
    Natcmp.natcmp(self.name, other.name)
  end
end