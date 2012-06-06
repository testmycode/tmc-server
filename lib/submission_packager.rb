require 'tmpdir'
require 'fileutils'
require 'pathname'
require 'shellwords'
require 'system_commands'
require 'tmc_junit_runner'
require 'tmc_dir_utils'

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager
  include SystemCommands

  def package_submission(exercise, zip_path, tar_path)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('received')
        FileUtils.mkdir_p('dest')
        Dir.chdir('received') do
          sh! ['unzip', zip_path]
          # Stupid OS X default zipper puts useless crap into zip files :[
          # Delete them or they might be mistaken for the actual source files later
          FileUtils.rm_rf '__MACOSX'
          # Let's clean up other similarly useless files while we're at it
          FileUtils.rm_f ['.DS_Store', 'desktop.ini', 'Thumbs.db', '.directory']
        end

        src_dir_path = TmcDirUtils.find_dir_containing(dir, "src")
        raise 'No src directory' if src_dir_path == nil
        received = Pathname(src_dir_path)

        cloned = Pathname(exercise.clone_path)
        dest = Pathname('dest')

        FileUtils.cp_r(cloned + 'lib', dest + 'lib')
        FileUtils.mkdir_p(dest + 'lib' + 'testrunner')
        for jar_path in TmcJunitRunner.jar_and_lib_paths
          FileUtils.cp(jar_path, dest + 'lib' + 'testrunner' + jar_path.basename)
        end

        FileUtils.cp_r(received + 'src', dest + 'src')
        FileUtils.cp_r(cloned  + 'test', dest + 'test')

        cloned.children(false).each do |filename|
          filename = filename.to_s
          FileUtils.cp(cloned + filename, dest + filename) unless (cloned + filename).directory?
        end

        tmc_project_file = TmcProjectFile.for_project(cloned.to_s)
        tmc_project_file.extra_student_files.each do |rel_path|
          from = "#{received}/#{rel_path}"
          to = "#{dest}/#{rel_path}"
          if File.exists?(from)
            FileUtils.rm(to) if File.exists?(to)
            FileUtils.mkdir_p(File.dirname(to))
            FileUtils.cp(from, to)
          end
        end

        FileUtils.cp(tmc_run_path, dest + 'tmc-run')
        sh! ['chmod', 'a+x', dest + 'tmc-run']

        sh! ['tar', '-C', dest.to_s, '-cpf', tar_path, '.']
      end
    end
  end
 
private
  def tmc_run_path
    "#{::Rails.root}/lib/testrunner/tmc-run"
  end
end

