# frozen_string_literal: true

require 'natcmp'

# Adds natsort methods to Ruby arrays and similar collections.
module Enumerable
  def natsort
    sort { |a, b| Natcmp.natcmp(a, b) }
  end

  def natsort!
    sort! { |a, b| Natcmp.natcmp(a, b) }
  end

  def natsort_by
    sort { |a, b| Natcmp.natcmp(yield(a), yield(b)) }
  end

  def natsort_by!
    sort! { |a, b| Natcmp.natcmp(yield(a), yield(b)) }
  end
end
