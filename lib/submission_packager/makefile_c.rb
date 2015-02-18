class SubmissionPackager
  class MakefileC < SubmissionPackager
    private

    def find_received_project_root(received_root)
      src_dir_path = TmcDirUtils.find_dir_containing(received_root, 'src')
      fail 'No src directory' if src_dir_path.nil?
      Pathname(src_dir_path)
    end

    def copy_files(exercise, received, dest, stub = nil, opts = {})
      cloned = Pathname(exercise.clone_path)
      tests = stub || cloned

      FileUtils.cp_r(received + 'src', dest + 'src')
      FileUtils.cp_r(tests + 'test', dest + 'test')
      FileUtils.cp(tests + 'Makefile', dest + 'Makefile')
      copy_files_in_dir_no_recursion(cloned, dest)

      tmc_project_file = TmcProjectFile.for_project(cloned.to_s)
      copy_extra_student_files(tmc_project_file, received, dest)

      copy_and_chmod_tmcrun(dest) unless opts[:no_tmc_run]
    end

    def tmc_run_path
      "#{::Rails.root}/lib/testrunner/tmc-run"
    end

    def c_runner_path
      "#{::Rails.root}/ext/TMCeeTestRunner/target/"
    end
  end
end
