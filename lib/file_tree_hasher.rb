require 'find'
require 'digest/sha2'

# Produces a combined hash of all the files and directories in a directory.
#
# This is currently used to cache part of the work done by CourseRefresher.
#
# The has depends on the files' paths as well as contents.
class FileTreeHasher
  def self.hash_file_tree(root_path)
    paths = []
    root_path = File.expand_path(root_path)
    Find.find(root_path) do |path|
      paths << path unless File.directory?(path)
    end

    paths.sort!

    digest = Digest::SHA2.new
    paths.each do |path|
      begin
        fail "Find didn't work as expected." unless path.start_with?(root_path)
        relative_path = path[(root_path.length + 1)...path.length]
        digest << relative_path << File.read(path)
      rescue
        raise "Failed to hash file #{path}: #{$!.message}"
      end
    end
    digest.hexdigest
  end
end
