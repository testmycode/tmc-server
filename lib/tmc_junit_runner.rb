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
  def get_test_case_methods(exercise_path)
    result = []
    ex_dir = ExerciseDir.new(exercise_path)
    ex_cp = ex_dir.library_jars.map(&:to_s).join(':')
    runner_cp = classpath
    
    Dir.mktmpdir do |tmpdir|
      stderr_file = "#{tmpdir}/stderr"
      cmd = mk_command([
        'java',
        '-cp',
        runner_cp + ':' + ex_cp,
        "#{package}.testscanner.TestScanner",
        ex_dir.path.to_s
      ])
      
      output = `#{cmd} 2>#{Shellwords.escape(stderr_file)}`
      
      if !$?.success?
        raise File.read(stderr_file)
      end
      
      result += parse_test_scanner_output(output)
    end
    result
  end
  
protected

  def parse_test_scanner_output(output)
    JSON.parse(output).map do |item|
      Hash[item.map {|k,v| [k.underscore.to_sym, v] }]
    end
  end
end

