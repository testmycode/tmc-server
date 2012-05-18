require 'pathname'
require 'find'

module TmcDirUtils
  extend TmcDirUtils

  def find_dir_containing(root, to_find)
    Pathname(root).find do |path|
      next unless path.directory?
      next unless (path + to_find).directory?
      return path
    end
    return nil
  end
end