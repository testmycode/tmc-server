require 'tempfile'
require 'find'
require 'shellwords'
require 'pathname'

module TestRunner
  extend SystemCommands

  def self.run_submission_tests(submission)
    FileUtils.mkdir_p "tmp/runs"
    Dir.mktmpdir("tmc-test-run", "tmp/runs") do |dir|
      project_root = populate_build_dir(dir, submission)
      compile_src(project_root)
      compile_tests(project_root)

      run_tests(project_root, submission)
    end
  end

private

  def self.testrunner_dir
    "#{::Rails.root}/lib/testrunner"
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

  def self.default_timeout
    60
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
    tests_classes = "#{exercise_dir}/build/test/classes"

    test_classes = find_test_classes tests_classes
    test_classes.each do |classname|
      run_test_class exercise_dir, classname, submission
    end
  end

  def self.run_test_class(exercise_dir, classname, submission)
    exercise_dir = Pathname.new(exercise_dir).realpath.to_s
    test_classes = "#{exercise_dir}/build/test/classes"
    src_classes = "#{exercise_dir}/build/classes"
    results_file = "#{exercise_dir}/results" #FIXME: put elsewhere

    command = [
      "java",
      "-cp",
      "#{lib_classpath(exercise_dir)}:#{src_classes}",
      
      "-Djava.security.manager",
      "-Djava.security.policy=#{policy_file}",
      
      # Properties for the policy file
      "-Dtmc.src_class_dir=#{src_classes}",
      "-Dtmc.test_class_dir=#{test_classes}",
      "-Dtmc.lib_dir=#{exercise_dir}/lib",
      "-Dtmc.exercise_dir=#{exercise_dir}",
      
      "fi.helsinki.cs.tmc.testrunner.Main",
      
      # Program arguments
      "#{test_classes}",
      classname,
      default_timeout,
      results_file
    ].map {|arg| Shellwords.escape(arg.to_s) }.join(' ')
    
    Dir.chdir(exercise_dir) do
      output = `#{command} 2>&1`
    end
    
    raise "Failed to run the testrunner (#{$?.inspect}). Output:\n#{output}" unless $?.success?
    
    results = ActiveSupport::JSON.decode IO.read(results_file)
    return unless results
    create_test_case_runs(submission, results)
    award_points(submission, results)
  end

  def self.find_test_classes(dir)
    test_classes = []
    Find.find(dir) do |path|
      next if FileTest.directory? path
      next if File.extname(path) != ".class"
      classname = path.chomp(File.extname(path))
      classname = classname.gsub(/^#{dir}\//, '')
      classname = classname.gsub(/\//, '.')
      test_classes << classname
    end
    test_classes
  end

  def self.replace_dir(source, destination)
    FileUtils.rm_rf destination
    FileUtils.cp_r source, destination
  end

  def self.cp_makefile(destination)
    FileUtils.cp makefile, destination
  end

  def self.get_all_available_points(project_root)
    methods = TmcJavalib.get_test_case_methods(project_root)
    methods.map {|m| m[:points] }.flatten.uniq
  end

  def self.populate_build_dir(dir, submission)
    system! "unzip -q #{submission.return_file_tmp_path} -d #{dir}"

    project_root = find_dir_containing(dir, "src")
    raise "unable to find 'src' directory in submission" unless project_root

    exercise = submission.exercise
    replace_dir("#{exercise.fullpath}/test", "#{project_root}/test")
    replace_dir("#{exercise.fullpath}/lib", "#{project_root}/lib")
    cp_makefile project_root

    raise "failed to cleanup" unless system "make -sC #{project_root} clean"

    return project_root
  end

  def self.create_test_case_runs(submission, results)
    results.each do |test_result|
      tcr = TestCaseRun.new(
        :test_case_name => "#{test_result["className"]} #{test_result["methodName"]}",
        :message => test_result["message"],
        :successful => test_result["status"] == 1
      )
      submission.test_case_runs << tcr
    end
  end

  def self.award_points(submission, results)
    user = submission.user
    awarded_points = user.awarded_points

    for point_name in points_from_test_results(results)
      if awarded_points.where(:name => point_name).empty?
        # To be saved with submission.
        submission.awarded_points << AwardedPoint.new(
          :name => point_name,
          :course => submission.exercise.course,
          :user => user
        )
        # Added here so we'll find it in subsequent calls
        user.awarded_points << user.awarded_points
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

