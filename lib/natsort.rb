
require 'natcmp'

module Enumerable
  def natsort
    self.sort {|a, b| Natcmp.natcmp(a, b) }
  end

  def natsort!
    self.sort! {|a, b| Natcmp.natcmp(a, b) }
  end

  def natsort_by(&block)
    self.sort {|a, b| Natcmp.natcmp(block.call(a), block.call(b)) }
  end

  def natsort_by!(&block)
    self.sort! {|a, b| Natcmp.natcmp(block.call(a), block.call(b)) }
  end
end
