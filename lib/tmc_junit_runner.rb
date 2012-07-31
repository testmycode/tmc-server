require 'shellwords'
require 'pathname'
require 'system_commands'
require 'maven_pom_file'

# Interface to tmc-junit-runner.
module TmcJunitRunner
  include SystemCommands
  extend TmcJunitRunner

  def project_path
    Pathname("#{::Rails.root}/ext/tmc-junit-runner")
  end

  def version
    pom_file.artifact_version
  end

  def jar_path
    Pathname("#{project_path}/target/tmc-junit-runner-#{version}.jar")
  end
  
  def lib_paths
    @lib_paths ||= build_classpath.split(':').map {|path| Pathname(path) }
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

  def pom_file
    @pom_file ||= MavenPomFile.new(pom_path)
  end

  def pom_path
    project_path + 'pom.xml'
  end
  
  def compiled?
    File.exists? jar_path
  end
  
  def compile!
    Dir.chdir(project_path) do
      output = `mvn -q package`
      raise "Failed to compile junit runner\n#{output}" unless $?.success?
    end
  end
  
  def clean_compiled_files!
    Dir.chdir(project_path) do
      system!('mvn -q clean')
    end
  end
  
  # Use TestScanner.get_test_case_methods instead.
  def get_test_case_methods(exercise_path)
    result = []
    ex_dir = ExerciseDir.get(exercise_path)
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

  def build_classpath
    file_path = "misc/tmc-junit-runner-build-classpath"
    begin
      too_old = FileStore.mtime(file_path) > File.mtime(jar_path)
    rescue # no such file most likely
      too_old = true
    end

    if !too_old
      cp = FileStore.try_get(file_path)
    else
      cp = nil
    end

    if !cp
      output = nil
      Dir.chdir(project_path) do
        output = `mvn org.apache.maven.plugins:maven-dependency-plugin:2.4:build-classpath`
      end
      if output =~ /\[INFO\] Dependencies classpath:\n(.*)\n/
        cp = $1.strip
        FileStore.put(file_path, cp)
      else
        raise "Failed to get build classpath of tmc-junit-runner."
      end
    end
    cp
  end
end

