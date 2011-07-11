require 'shellwords'

# Interface to tmc-javalib.
module TmcJavalib
  include SystemCommands

  def self.method_missing(*args)
    default_instance.send(*args)
  end
  
  def self.default_instance
    if @default_instance.nil?
      @default_instance = Object.new
      class << @default_instance; include TmcJavalib; end
    end
    @default_instance
  end
  
  def self.default_instance=(obj)
    @default_instance = obj
  end

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
  
  # Returns an array of hashes with
  # :class_name => 'UnqualifiedJavaClassName'
  # :method_name => 'testMethodName',
  # :exercises => ['exercise', 'annotation', 'values']
  #   (split by space from annotation value; empty if none)
  def get_exercise_methods(course_or_exercise_path)
    path = course_or_exercise_path
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

