# frozen_string_literal: true

class SubmissionPackager
  class JavaMaven < SubmissionPackager
    private
      def find_received_project_root(received_root)
        src_dir_path = TmcDirUtils.find_dir_containing(received_root, 'src')
        raise 'No src directory' if src_dir_path.nil?
        Pathname(src_dir_path)
      end

      def copy_files(exercise, received, dest, stub = nil, opts = {})
        cloned = Pathname(exercise.clone_path)
        tests = stub || cloned

        FileUtils.cp(cloned + 'pom.xml', dest)

        FileUtils.mkdir_p(dest + 'src')
        cp_r_if_exists(received + 'src' + 'main', dest + 'src')
        cp_r_if_exists(tests + 'src' + 'test', dest + 'src')

        copy_files_in_dir_no_recursion(cloned, dest)

        tmc_project_file = TmcProjectFile.for_project(cloned.to_s)
        copy_extra_student_files(tmc_project_file, received, dest)

        config = TmcLangs.get.get_exercise_config(exercise.clone_path)
        config['studentFilePaths'].each do |folder|
          src = received + folder
          FileUtils.cp_r(src, dest + folder) if FileTest.exist?(src)
        end
        config['exerciseFilePaths'].each do |folder|
          src = tests + folder
          FileUtils.cp_r(src, dest + folder) if FileTest.exist?(src)
        end

        copy_and_chmod_tmcrun(dest) unless opts[:no_tmc_run]
        copy_tmc_langs(dest) if opts[:include_tmc_langs]
      end

      def tmc_run_path
        "#{::Rails.root}/lib/testrunner/tmc-run"
      end
  end
end
