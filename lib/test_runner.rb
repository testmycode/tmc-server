require 'tempfile'
require 'find'

module TestRunner

  def self.lib_path
    "#{::Rails.root}/lib/testrunner/"
  end

  def self.jar_path
    "#{lib_path}/jar"
  end

  def self.makefile
    "#{lib_path}/Makefile"
  end

  def self.classpath
    Dir.glob("#{jar_path}/*.jar").join(":")
  end

  def self.find_dir_containing root, seeked
    Find.find(root) do |path|
      next unless FileTest.directory? path
      next unless FileTest.directory? "#{path}/#{seeked}"
      return path
    end
    return nil
  end

  def self.compile_src project_root
    system "env CLASSPATH=#{classpath} make -sC #{project_root} build-src"
  end

  def self.compile_tests project_root
    system "env CLASSPATH=#{classpath} make -sC #{project_root} build-test"
  end

  def self.run_tests exercise_dir, suite_run
    tests_classpath = "#{exercise_dir}/build/test/classes"

    test_classes = find_test_classes tests_classpath
    test_classes.each do |classname|
      run_test_class exercise_dir, classname, suite_run
    end
  end

  def self.run_test_class exercise_dir, classname, suite_run
    test_classpath = "#{exercise_dir}/build/test/classes"
    src_classpath = "#{exercise_dir}/build/classes"
    results_fn = "#{exercise_dir}/results"

    pid = Process.fork do
      Process.setrlimit Process::RLIMIT_CPU, 10, 10
      exec "java", "-cp", "#{classpath}:#{src_classpath}",
        "-Djava.security.manager",
        "-Djava.security.policy=#{lib_path}/testrunner_policy",
        "fi.helsinki.cs.tmc.testrunner.Main", "run", test_classpath, classname,
        "/dev/null", results_fn
    end

    Process.waitpid(pid)

    results = ActiveSupport::JSON.decode IO.read(results_fn)
    return unless results

    results.each do |exercise_name, test_results|
      test_results.each do |test_result|
        TestCaseRun.create(:exercise => exercise_name,
                           :method_name => test_result["methodName"],
                           :class_name => test_result["className"],
                           :message => test_result["message"],
                           :success => test_result["status"] == 1,
                           :test_suite_run_id => suite_run.id)
      end
    end
  end

  def self.find_test_classes classpath
    test_classes = []
    Find.find(classpath) do |path|
      next if FileTest.directory? path
      next if File.extname(path) != ".class"
      classname = path.chomp(File.extname(path))
      classname = classname.gsub(/^#{classpath}\//, '')
      classname = classname.gsub(/\//, '.')
      test_classes << classname
    end
    test_classes
  end

  def self.cp_dir source, destination
    Dir.chdir source do
      Dir.glob("*").each do |file|
        FileUtils.cp_r file, destination
      end
    end
  end

  def self.cp_makefile destination
    FileUtils.cp makefile, destination
  end

  def self.extract_exercise_list project_root
    exercises = []

    Dir.mktmpdir do |dir|
      cp_dir project_root, dir
      cp_makefile dir
      raise "failed to compile tests" unless compile_tests dir
      test_classpath = "#{dir}/build/test/classes"
      src_classpath = "#{dir}/build/classes"

      test_classes = find_test_classes "#{test_classpath}"
      results_fn = "#{dir}/results"

      test_classes.each do |classname|
        system "java", "-cp", "#{classpath}:#{src_classpath}",
        "fi.helsinki.cs.tmc.testrunner.Main", "list", test_classpath,
        classname, "/dev/null", results_fn

        class_exercises = ActiveSupport::JSON.decode IO.read(results_fn)
        if class_exercises.is_a? Array
          exercises.concat(class_exercises)
        end
      end
    end

    return exercises
  end

  def self.populate_build_dir dir, course, exercise, submission
    Tempfile.open(['submission', '.zip']) do |tempfile|
      tempfile.write(submission.return_file)
      tempfile.close
      system "unzip -q #{tempfile.path} -d #{dir}"
    end

    project_root = find_dir_containing dir, "src"
    raise "unable to find 'src' directory in submision" unless project_root

    source = "#{course.clone_path}/#{exercise.path}/test"
    FileUtils.rm_rf "#{project_root}/test"
    FileUtils.cp_r source, project_root
    cp_makefile project_root

    raise "failed to cleanup" unless system "make -sC #{project_root} clean"

    return project_root
  end

  def self.test_suite_run test_suite_run
    submission = ExerciseReturn.find(test_suite_run.exercise_return_id)
    exercise = Exercise.find(submission.exercise_id)
    course = Course.find(exercise.course_id)

    test_suite_run.status = 0
    submission.test_suite_runs << test_suite_run
    test_suite_run.save

    Dir.mktmpdir do |dir|
      project_root = populate_build_dir dir, course, exercise, submission
      raise "unable to find source directory (src)" unless project_root
      raise "failed to compile submission" unless compile_src project_root
      raise "failed to compile tests" unless compile_tests project_root

      run_tests project_root, test_suite_run
    end

    test_suite_run.status = 1
    test_suite_run.save
  end
end

