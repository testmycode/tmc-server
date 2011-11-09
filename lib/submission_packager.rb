require 'tmpdir'
require 'fileutils'
require 'find'
require 'shellwords'
require 'system_commands'

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager
  include SystemCommands

  def package_submission(exercise, zip_path, tar_path)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        sh! ['unzip', zip_path]
        
        project_root = find_dir_containing(dir, "src")
        sh! ['tar', '-C', project_root, '-cvf', tar_path, 'src']
        sh! ['tar', '-C', exercise.fullpath, '-rvf', tar_path, 'lib', 'test']
      end
    end
  end
 
private
  def find_dir_containing(root, to_find)
    Find.find(root) do |path|
      next unless FileTest.directory? path
      next unless FileTest.directory? "#{path}/#{to_find}"
      return path
    end
    return nil
  end
end

