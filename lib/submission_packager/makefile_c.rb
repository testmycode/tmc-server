class SubmissionPackager
  class MakefileC < SubmissionPackager
  private
    def find_received_project_root(received_root)
      src_dir_path = TmcDirUtils.find_dir_containing(received_root, "src")
      raise 'No src directory' if src_dir_path == nil
      Pathname(src_dir_path)
    end

    def copy_files(exercise, received, dest)
      cloned = Pathname(exercise.clone_path)

      copy_tmcee_libs(cloned, dest)
      FileUtils.cp_r(received + 'src', dest + 'src')
      FileUtils.cp_r(cloned  + 'test', dest + 'test')
      copy_files_in_dir_no_recursion(cloned, dest)

      tmc_project_file = TmcProjectFile.for_project(cloned.to_s)
      copy_extra_student_files(tmc_project_file, received, dest)

      FileUtils.cp(tmc_run_path, dest + 'tmc-run')
      sh! ['chmod', 'a+x', dest + 'tmc-run']
    end

    def copy_tmcee_libs(cloned, dest)
      Dir.glob("#{c_runner_path}*.jar").each do |jar|
        #if jar.include? "tmc-c-test-runner-" and jar.include? "SNAPSHOT.jar"
        jarname = jar.split("/").last.split(".").first
        FileUtils.cp(jar, dest+ 'lib' + 'testrunner' + 'c-test-runner.jar')
        #end
      end
    end

    def tmc_run_path
      "#{::Rails.root}/lib/testrunner/tmc-run"
    end

    def c_runner_path
      "#{::Rails.root}/ext/TMCeeTestRunner/target/"
    end
  end
end
