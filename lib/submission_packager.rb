require 'tmpdir'
require 'fileutils'
require 'find'
require 'shellwords'
require 'system_commands'
require 'tmc_junit_runner'

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager
  include SystemCommands

  def package_submission(exercise, zip_path, tar_path)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        sh! ['unzip', zip_path]
        
        project_root = find_dir_containing(dir, "src")
        
        FileUtils.rm_rf("#{project_root}/lib")
        FileUtils.mkdir_p("#{project_root}/lib/testrunner")
        for jar_path in TmcJunitRunner.jar_and_lib_paths
          FileUtils.cp(jar_path, "#{project_root}/lib/testrunner/#{jar_path.basename}")
        end
        
        sh! ['tar', '-C', project_root, '-cf', tar_path, 'src', 'lib']
        sh! ['tar', '-C', exercise.fullpath, '-rf', tar_path, 'lib', 'test']
        
        write_tests_file(exercise, 'tests.txt')
        sh! ['tar', '-rf', tar_path, 'tests.txt']
        
        FileUtils.cp(tmc_run_path, "./")
        sh! ['chmod', 'a+x', 'tmc-run']
        sh! ['tar', '-rpf', tar_path, 'tmc-run']
      end
    end
  end
 
private
  def tmc_run_file_names
    Dir.entries(tmc_run_dir) - ['.', '..']
  end

  def tmc_run_path
    "#{::Rails.root}/lib/testrunner/tmc-run"
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

