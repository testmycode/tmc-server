require 'find'
require 'digest/sha2'

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
      raise "Find didn't work as expected." unless path.start_with?(root_path)
      relative_path = path[(root_path.length+1)...path.length]
      digest << relative_path << File.read(path)
    end
    digest.hexdigest
  end
end

