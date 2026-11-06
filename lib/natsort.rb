# typed: strict
# frozen_string_literal: true

require 'natcmp'

# Adds natsort methods to Ruby arrays and similar collections.
# Sigs live in sorbet/rbi/shims/lib_natsort.rbi: an inline sig can't name Enumerable's Elem at runtime.
module Enumerable
  def natsort
    sort { |a, b| Natcmp.natcmp(a, b) }
  end

  def natsort_by
    sort { |a, b| Natcmp.natcmp(yield(a), yield(b)) }
  end
end

class Array
  def natsort!
    sort! { |a, b| Natcmp.natcmp(a, b) }
  end

  def natsort_by!
    sort! { |a, b| Natcmp.natcmp(yield(a), yield(b)) }
  end
end
