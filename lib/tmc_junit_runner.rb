require 'shellwords'
require 'pathname'
require 'system_commands'

# Interface to tmc-junit-runner.
module TmcJunitRunner
  include SystemCommands
  extend TmcJunitRunner

  def project_path
    Pathname("#{::Rails.root}/ext/tmc-junit-runner")
  end

  def jar_path
    Pathname("#{project_path}/dist/tmc-junit-runner.jar")
  end
  
  def lib_paths
    [Pathname("#{project_path}/lib/gson-2.0.jar"), Pathname("#{project_path}/lib/junit-4.10.jar")]
  end
  
  def jar_and_lib_paths
    [jar_path] + lib_paths
  end
  
  def package
    "fi.helsinki.cs.tmc"
  end
  
  def classpath
    "#{jar_path}:#{lib_paths.join(':')}"
  end
  
  def compiled?
    File.exists? jar_path
  end
  
  def compile!
    Dir.chdir(project_path) do
      output = `ant -q jar`
      raise "Failed to compile junit runner\n#{output}" unless $?.success?
    end
  end
  
  def clean_compiled_files!
    Dir.chdir(project_path) do
      system!('ant -q clean')
    end
  end
  
  # Use TestScanner.get_test_case_methods instead.
  def get_test_case_methods(course_or_exercise_path)
    result = []
    ExerciseDir.find_exercise_dirs(course_or_exercise_path).each do |exdir|
      ex_cp = exdir.library_jars.map(&:to_s).join(':')
      runner_cp = classpath
      cmd = mk_command([
        'java',
        '-cp',
        runner_cp + ':' + ex_cp,
        "#{package}.testscanner.TestScanner",
        exdir.path.to_s
      ])
      output = `#{cmd}`
      result += parse_test_scanner_output(output)
    end
    result
  end
  
protected

  def find_project_dirs(path)
    ExerciseDir.find_exercise_dirs(path)
    result = []
    Pathname(path).find do |entry|
      result << entry.parent if entry.directory? && entry.basename == 'test'
    end
    result
  end

  def parse_test_scanner_output(output)
    JSON.parse(output).map do |item|
      Hash[item.map {|k,v| [k.underscore.to_sym, v] }]
    end
  end
end

