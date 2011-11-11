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
        sh! ['tar', '-C', project_root, '-cf', tar_path, 'src']
        sh! ['tar', '-C', exercise.fullpath, '-rf', tar_path, 'lib', 'test']
        
        write_tests_file(exercise, 'tests.txt')
        sh! ['tar', '-rf', tar_path, 'tests.txt']
        
        tmc_run_file_names.each do |file|
          FileUtils.cp("#{tmc_run_dir}/#{file}", "./#{file}")
        end
        FileUtils.chmod 'a+x', 'tmc-run'
        sh! ['tar', '-rpf', tar_path, *tmc_run_file_names]
      end
    end
  end
 
private
  def tmc_run_file_names
    Dir.entries(tmc_run_dir) - ['.', '..']
  end

  def tmc_run_dir
    "#{::Rails.root}/lib/testrunner"
  end

  def find_dir_containing(root, to_find)
    Find.find(root) do |path|
      next unless FileTest.directory? path
      next unless FileTest.directory? "#{path}/#{to_find}"
      return path
    end
    return nil
  end
  
  def write_tests_file(exercise, tests_file_name)
    File.open(tests_file_name, 'w') do |file|
      TestScanner.get_test_case_methods(exercise.fullpath).map do |m|
        file.write(m[:class_name] + "." + m[:method_name] + "{" + m[:points].join(',') + "}\n")
      end
    end
  end
end

