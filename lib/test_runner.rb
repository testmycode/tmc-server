require 'tempfile'
require 'find'

module TestRunner
  extend SystemCommands

  def self.run_submission_tests(submission)
    exercise = Exercise.find(submission.exercise_id)
    course = Course.find(exercise.course_id)

    Dir.mktmpdir do |dir|
      project_root = populate_build_dir(dir, course, exercise, submission)
      compile_src(project_root)
      compile_tests(project_root)

      run_tests(project_root, submission)
    end
  end

private

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
    output = `env CLASSPATH=#{classpath} make -sC #{project_root} #{target} 2>&1`
    raise "Compilation error:\n#{output}" unless $?.success?
  end

  def self.run_tests(exercise_dir, submission)
    tests_classpath = "#{exercise_dir}/build/test/classes"

    test_classes = find_test_classes tests_classpath
    test_classes.each do |classname|
      run_test_class exercise_dir, classname, submission
    end
  end

  def self.run_test_class(exercise_dir, classname, submission)
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
        tcr = TestCaseRun.new(
          :exercise => exercise_name,
          :method_name => test_result["methodName"],
          :class_name => test_result["className"],
          :message => test_result["message"],
          :success => test_result["status"] == 1,
          :submission_id => submission.id
        )
        submission.test_case_runs << tcr
      end
    end
  end

  def self.find_test_classes(classpath)
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

  def self.cp_dir(source, destination)
    Dir.chdir source do
      Dir.glob("*").each do |file|
        FileUtils.cp_r file, destination
      end
    end
  end

  def self.cp_makefile(destination)
    FileUtils.cp makefile, destination
  end

  def self.extract_exercise_list(project_root)
    methods = TmcJavalib.get_exercise_methods(project_root)
    methods.map {|m| m[:exercises] }.flatten
  end

  def self.populate_build_dir(dir, course, exercise, submission)
    system! "unzip -q #{submission.return_file_tmp_path} -d #{dir}"

    project_root = find_dir_containing(dir, "src")
    raise "unable to find 'src' directory in submission" unless project_root

    source = "#{course.clone_path}/#{exercise.path}/test"
    FileUtils.rm_rf "#{project_root}/test"
    FileUtils.cp_r source, project_root
    cp_makefile project_root

    raise "failed to cleanup" unless system "make -sC #{project_root} clean"

    return project_root
  end
end

