require 'tmpdir'
require 'fileutils'
require 'pathname'
require 'shellwords'
require 'system_commands'
require 'tmc_junit_runner'
require 'tmc_dir_utils'
require 'submission_packager/java_simple'
require 'submission_packager/java_maven'
require 'submission_packager/makefile_c'

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager
  def self.get(exercise)
    cls_name = exercise.exercise_type.to_s.camelize
    cls = SubmissionPackager.const_get(cls_name)
    cls.new
  end

  # Packages a submitted ZIP of the given exercise into a TAR or a ZIP with tests
  # added from the clone (to ensure they haven't been tampered with).
  #
  # - zip_path must be the path to the submitted zip.
  # - return_file_path is the path to the file to be generated.
  # - extra_params are written as shell export statements into into .tmcparams.
  # - config options:
  #   - tests_from_stub: includes tests from the stub instead of the clone.
  #                      This effectively excludes hidden tests.
  #   - include_ide_files: includes IDE settings from the submission,
  #                        or from the clone if none in the submission
  #                        (as is usually the case).
  #   - no_tmc_run: does not include the tmc-run file
  #   - format: may be set to :zip to get a zip file. Defaults to :tar.
  def package_submission(exercise, zip_path, return_file_path, extra_params = {}, config = {})
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('received')
        FileUtils.mkdir_p('dest')

        Dir.chdir('received') do
          sh! ['unzip', zip_path]
          remove_os_rubbish_files!
        end

        received = Pathname(find_received_project_root(Pathname('received')))
        dest = Pathname('dest')

        extra_params = if extra_params then extra_params.clone else {} end
        extra_params['runtime_params'] = exercise.runtime_params_array
        write_extra_params(dest + '.tmcparams', extra_params)

        if config[:include_ide_files]
          copy_ide_files(Pathname(exercise.clone_path), received, dest)
        end

        # To get hidden tests etc, gsub stub with clone path...
        if config[:tests_from_stub]
          FileUtils.mkdir_p('stub')
          Dir.chdir('stub') do
            sh! ['unzip', exercise.stub_zip_file_path]
            remove_os_rubbish_files!
          end
          stub = Pathname(find_received_project_root(Pathname('stub')))

          copy_files(exercise, received, dest, stub, no_tmc_run: config[:no_tmc_run])
        else
          copy_files(exercise, received, dest, nil, no_tmc_run: config[:no_tmc_run])
        end

        if config[:format] == :zip
          Dir.chdir(dest) do
            sh! ['zip', '-r', return_file_path, '.']
          end
        else
          sh! ['tar', '-C', dest.to_s, '-cpf', return_file_path, '.']
        end
      end
    end
  end

  def get_full_zip(submission)
    exercise = submission.exercise
    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      return_zip_path = "#{tmpdir}/submission_to_be_returned.zip"
      File.open(zip_path, 'wb') {|f| f.write(submission.return_file) }
      package_submission(exercise, zip_path, return_zip_path, submission.params,
        tests_from_stub: true,
        include_ide_files: true,
        format: :zip,
        no_tmc_run: true
      )
      File.read(return_zip_path)
    end
  end

private
  include SystemCommands

  def find_received_project_root(received_root)
    raise "Implemented by subclass"
  end

  # Stupid OS X default zipper puts useless crap into zip files :[
  # Delete them or they might be mistaken for the actual source files later.
  # Let's clean up other similarly useless files while we're at it.
  def remove_os_rubbish_files!
    FileUtils.rm_f %w(.DS_Store desktop.ini Thumbs.db .directory __MACOSX)
  end

  # All parameters are pathname objects
  def copy_files(exercise, received, dest, stub = nil, opts = {})
    raise "Implemented by subclass"
  end

  def copy_ide_files(clone, received, dest)
    # NetBeans
    cp_r_if_exists([received + 'nbproject', clone + 'nbproject'].find(&:exist?), dest)

    # Eclipse
    cp_r_if_exists([received + '.classpath', clone + '.classpath'].find(&:exist?), dest)
    cp_r_if_exists([received + '.project', clone + '.project'].find(&:exist?), dest)
    cp_r_if_exists([received + '.settings', clone + '.settings'].find(&:exist?), dest)

    # IDEA
    cp_r_if_exists([received + '.idea', clone + '.idea'].find(&:exist?), dest)
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
    if src != nil && File.exist?(src)
      FileUtils.cp_r(src, dest)
    end
  end

  def copy_and_chmod_tmcrun(dest)
    FileUtils.cp(tmc_run_path, dest + 'tmc-run')
    sh! ['chmod', 'a+x', dest + 'tmc-run']
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

  def write_extra_params(file, extra_params)
    File.open(file, 'wb') do |f|
      extra_params.each do |k, v|
        v = "" if v == nil
        escaped_v = if v.is_a?(Array) then SystemCommands.make_bash_array(v) else Shellwords.escape(v) end
        f.puts 'export ' + Shellwords.escape(k) + '=' + escaped_v
      end
    end
  end
end

