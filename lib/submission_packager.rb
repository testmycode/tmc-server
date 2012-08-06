require 'tmpdir'
require 'fileutils'
require 'pathname'
require 'shellwords'
require 'system_commands'
require 'tmc_junit_runner'
require 'tmc_dir_utils'
require 'submission_packager/java_simple'
require 'submission_packager/java_maven'

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager

  def self.get(exercise)
    cls_name = exercise.exercise_type.to_s.camelize
    cls = SubmissionPackager.const_get(cls_name)
    cls.new
  end

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

        received = Pathname(find_received_project_root(Pathname('received')))
        dest = Pathname('dest')
        copy_files(exercise, received, dest)

        sh! ['tar', '-C', dest.to_s, '-cpf', tar_path, '.']
      end
    end
  end

private
  include SystemCommands

  def find_received_project_root(received_root)
    raise "Implemented by subclass"
  end

  # All parameters are pathname objects
  def copy_files(received, cloned, dest)
    raise "Implemented by subclass"
  end

  # Some utilities
  def copy_files_in_dir_no_recursion(src, dest)
    src = Pathname(src)
    dest = Pathname(dest)
    src.children(false).each do |filename|
      filename = filename.to_s
      FileUtils.cp(src + filename, dest + filename) unless (src + filename).directory?
    end
  end

  def cp_r_if_exists(src, dest)
    if File.exist?(src)
      FileUtils.cp_r(src, dest)
    end
  end

  def copy_extra_student_files(tmc_project_file, received, dest)
    tmc_project_file.extra_student_files.each do |rel_path|
      from = "#{received}/#{rel_path}"
      to = "#{dest}/#{rel_path}"
      if File.exists?(from)
        FileUtils.rm(to) if File.exists?(to)
        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.cp(from, to)
      end
    end
  end
end

