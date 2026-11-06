# typed: strict
# frozen_string_literal: true

require 'pathname'
require 'find'

module TmcDirUtils
  extend T::Sig
  extend T::Helpers
  requires_ancestor { Kernel }

  extend TmcDirUtils

  sig { params(root: T.any(String, Pathname), to_find: String).returns(T.nilable(Pathname)) }
  def find_dir_containing(root, to_find)
    Pathname(root).find do |path|
      next unless path.directory?
      next unless (path + to_find).directory?
      return path
    end
    nil
  end
end
