require 'shellwords'
require 'system_commands'

# Interface to tmc-javalib.
module TmcJavalib
  include SystemCommands
  extend TmcJavalib

  def project_path
    "#{::Rails.root}/lib/tmc-javalib"
  end

  def jar_path
    "#{project_path}/dist/tmc-javalib.jar"
  end
  
  def package
    "fi.helsinki.cs.tmc"
  end
  
  def classpath
    "#{jar_path}:#{project_path}/lib/gson-1.7.1.jar:#{project_path}/lib/junit-4.8.2.jar"
  end
  
  def compiled?
    File.exists? jar_path
  end
  
  def compile!
    Dir.chdir(project_path) do
      output = `ant -q jar`
      raise "Failed to compile javalib\n#{output}" unless $?.success?
    end
  end
  
  def clean_compiled_files!
    Dir.chdir(project_path) do
      system!('ant -q clean')
    end
  end
  
  # Use TestScanner.get_test_case_methods instead as it provides caching.
  def get_test_case_methods(course_or_exercise_path)
    path = course_or_exercise_path
    # TODO: the classpath is insufficient and results in errors being printed to stderr,
    # but everything seems to work still.
    cmd = "java -cp #{Shellwords.escape(classpath)} #{package}.testscanner.TestScanner #{Shellwords.escape(path)}"
    output = `#{cmd}`
    parse_test_scanner_output(output)
  end
  
protected

  def parse_test_scanner_output(output)
    JSON.parse(output).map do |item|
      Hash[item.map {|k,v| [k.underscore.to_sym, v] }]
    end
  end
end

