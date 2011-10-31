require 'system_commands'
require 'tempfile'
require 'find'
require 'pathname'

module TestRunner
  extend SystemCommands

  def self.run_submission_tests(submission)
    FileUtils.mkdir_p sandbox_root_dir
    Dir.mktmpdir("tmc-sandbox", sandbox_root_dir) do |dir|
      project_root = populate_build_dir(dir, submission)
      compile_src(project_root)
      compile_tests(project_root)

      results = run_tests(project_root, submission)
      
      if !submission.new_record?
        submission.test_case_runs.destroy_all
      end
      
      create_test_case_runs(submission, results)
      award_points(submission, results)
    end
  end

private

  def self.testrunner_dir
    "#{::Rails.root}/lib/testrunner"
  end
  
  def self.sandbox_root_dir
    "#{::Rails.root}/tmp/sandboxes"
  end

  def self.makefile
    "#{testrunner_dir}/Makefile"
  end

  def self.policy_file
    "#{testrunner_dir}/testrunner.policy"
  end
  
  def self.lib_classpath(exercise_dir)
    Dir.glob("#{exercise_dir}/lib/*.jar").join(":")
  end

  def self.find_dir_containing(root, seeked)
    Find.find(root) do |path|
      next unless FileTest.directory? path
      next unless FileTest.directory? "#{path}/#{seeked}"
      return path
    end
    return nil
  end

  def self.compile_src(project_root)
    compile_target(project_root, 'build-src')
  end

  def self.compile_tests(project_root)
    compile_target(project_root, 'build-test')
  end

  def self.compile_target(project_root, target)
    output = `make -sC #{project_root} #{target} 2>&1`
    raise "Compilation error:\n#{output}" unless $?.success?
  end

  def self.run_tests(exercise_dir, submission)
    exercise_dir = Pathname.new(exercise_dir).realpath.to_s
    test_classes = "#{exercise_dir}/build/test/classes"
    src_classes = "#{exercise_dir}/build/classes"
    results_file = "#{exercise_dir}/results" #FIXME: put elsewhere
    
    test_methods = TestScanner.get_test_case_methods(exercise_dir).map do |m|
      m[:class_name] + "." + m[:method_name] + "{" + m[:points].join(',') + "}"
    end
    
    command = mk_command([
      "java",
      "-cp",
      "#{lib_classpath(exercise_dir)}:#{src_classes}:#{test_classes}",
      
      "-Djava.security.manager",
      "-Djava.security.policy=#{policy_file}",
      
      # Properties for the policy file and the program
      "-Dtmc.exercise_dir=#{exercise_dir}",
      "-Dtmc.src_class_dir=#{src_classes}",
      "-Dtmc.test_class_dir=#{test_classes}",
      "-Dtmc.lib_dir=#{exercise_dir}/lib",
      "-Dtmc.results_file=#{results_file}",
      
      "fi.helsinki.cs.tmc.testrunner.Main"
    ] + test_methods)
    
    Dir.chdir(exercise_dir) do
      output = `#{command} 2>&1`
      raise "Failed to run the testrunner (#{$?.inspect}). Output:\n#{output}" unless $?.success?
    end
    
    results = ActiveSupport::JSON.decode IO.read(results_file)
    raise 'Got no test results from test runner' unless results
    
    results
  end

  def self.populate_build_dir(dir, submission)
    if submission.new_record?
      unzip(submission.return_file_tmp_path, dir)
    else
      Tempfile.open(['tmc-rerun', '.zip'], :encoding => 'ascii-8bit') do |tmpfile|
        tmpfile.write(submission.return_file)
        tmpfile.flush
        unzip(tmpfile.path, dir)
      end
    end

    project_root = find_dir_containing(dir, "src")
    raise "unable to find 'src' directory in submission" unless project_root

    exercise = submission.exercise
    replace_dir("#{exercise.fullpath}/test", "#{project_root}/test")
    replace_dir("#{exercise.fullpath}/lib", "#{project_root}/lib")
    cp_makefile project_root

    raise "failed to clean up" unless system "make -sC #{project_root} clean"

    return project_root
  end
  
  def self.unzip(zip_file, dir)
    sh! 'unzip', '-q', zip_file, '-d', dir
  end
  
  def self.replace_dir(source, destination)
    FileUtils.rm_rf destination
    FileUtils.cp_r source, destination
  end

  def self.cp_makefile(destination)
    FileUtils.cp makefile, destination
  end

  def self.create_test_case_runs(submission, results)
    results.each do |test_result|
      tcr = TestCaseRun.new(
        :test_case_name => "#{test_result["className"]} #{test_result["methodName"]}",
        :message => test_result["message"],
        :successful => test_result["status"] == 1 #FIXME: use descriptive strings instead of magic numbers
      )
      submission.test_case_runs << tcr
    end
  end

  def self.award_points(submission, results)
    user = submission.user
    exercise = submission.exercise
    course = exercise.course
    awarded_points = AwardedPoint.exercise_user_points(exercise, user)

    for point_name in points_from_test_results(results)
      unless awarded_points.include?(point_name)
        submission.awarded_points << AwardedPoint.new(
          :name => point_name,
          :course => course,
          :user => user
        )
      end
    end
  end

  def self.points_from_test_results(results)
    results.reduce({}) do |points, result|
      result["pointNames"].each do |name|
        unless points[name] == false
          points[name] = (result["status"] == 1)
        end
      end
      points
    end.reduce([]) do |point_names, (name, success)|
      point_names << name if success
      point_names
    end
  end
end

