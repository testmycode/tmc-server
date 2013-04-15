class SubmissionPackager
  class Universal < SubmissionPackager
  private
    def find_received_project_root(received_root)
      src_dir_path = TmcDirUtils.find_dir_containing(received_root, ".universal")
      raise 'No src directory' if src_dir_path == nil
      root_path = src_dir_path.to_s.split("/")[0..-1].join("/")
      Pathname(root_path)
    end

    def copy_files(exercise, received, dest)
      cloned = Pathname(exercise.clone_path)

      FileUtils.cp_r(received.realpath.to_s + '/.', dest)
      FileUtils.cp_r(cloned  + '.universal/private', dest + '.universal/')
      FileUtils.cp_r(cloned  + '.universal/controls', dest + '.universal/')
      copy_files_in_dir_no_recursion(cloned, dest)

      tmc_project_file = TmcProjectFile.for_project(cloned.to_s)
      copy_extra_student_files(tmc_project_file, received, dest)

      FileUtils.cp(tmc_run_path, dest + 'tmc-run')
      sh! ['chmod', 'a+x', dest + 'tmc-run']
    end


    def tmc_run_path
      "#{::Rails.root}/lib/testrunner/tmc-run"
    end

  end
end
