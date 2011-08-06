require 'tempfile'
require 'find'

module TestRunner
  extend SystemCommands

  def self.run_submission_tests(submission)
    Dir.mktmpdir do |dir|
      project_root = populate_build_dir(dir, submission)
      compile_src(project_root)
      compile_tests(project_root)

      run_tests(project_root, submission)
    end
  end

private

  def self.sandbox_root
    "#{::Rails.root}/lib/testrunner/"
  end

  def self.makefile
    "#{sandbox_root}/Makefile"
  end

  def self.policy_file
    "#{sandbox_root}/testrunner.policy"
  end

  def self.default_timeout
    60
  end

  def self.classpath
    TmcJavalib.classpath
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

    system! "java -cp #{classpath}:#{src_classpath} " +
      "fi.helsinki.cs.tmc.testrunner.Main #{test_classpath} #{classname} " +
      "#{default_timeout} #{results_fn} /dev/null #{policy_file}"
    results = ActiveSupport::JSON.decode IO.read(results_fn)
    return unless results
    create_test_case_runs(submission, results)
    award_points(submission, results)
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

  def self.get_all_available_points(project_root)
    methods = TmcJavalib.get_test_case_methods(project_root)
    methods.map {|m| m[:points] }.flatten.uniq
  end

  def self.populate_build_dir(dir, submission)
    system! "unzip -q #{submission.return_file_tmp_path} -d #{dir}"

    project_root = find_dir_containing(dir, "src")
    raise "unable to find 'src' directory in submission" unless project_root

    exercise = submission.exercise
    source = "#{exercise.course.clone_path}/#{exercise.path}/test"
    FileUtils.rm_rf "#{project_root}/test"
    FileUtils.cp_r source, project_root
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
        # FUUU create
        submission.awarded_points << AwardedPoint.new(
          :name => point_name,
          :course => submission.exercise.course,
          :user => user
        )
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

