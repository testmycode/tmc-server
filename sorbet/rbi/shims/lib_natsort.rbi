# typed: strict

# Sigs for the monkeypatch in lib/natsort.rb, which can't name Elem at runtime.
# The sort key is nilable only because model name columns are; a nil key raises.

module Enumerable
  sig { returns(T::Array[Elem]) }
  def natsort; end

  sig { params(blk: T.proc.params(arg0: Elem).returns(T.nilable(String))).returns(T::Array[Elem]) }
  def natsort_by(&blk); end
end

class Array
  sig { returns(T.self_type) }
  def natsort!; end

  sig { params(blk: T.proc.params(arg0: Elem).returns(T.nilable(String))).returns(T.self_type) }
  def natsort_by!(&blk); end
end
