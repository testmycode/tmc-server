require 'shellwords'

# Interface to tmc-javalib
module TmcJavalib
  extend SystemCommands

  def self.project_path
    "#{::Rails.root}/lib/tmc-javalib"
  end

  def self.jar_path
    "#{project_path}/dist/tmc-javalib.jar"
  end
  
  def self.compiled?
    File.exists? jar_path
  end
  
  def self.compile!
    Dir.chdir(project_path) do
      output = `ant -q jar`
      raise "Failed to compile javalib\n#{output}" unless $?.success?
    end
  end
  
  def self.clean_compiled_files!
    Dir.chdir(project_path) do
      system!('ant -q clean')
    end
  end
  
  # Returns an array of hashes with
  # :class_name => 'UnqualifiedJavaClassName'
  # :method_name => 'testMethodName',
  # :exercises => ['exercise', 'annotation', 'values']
  #   (split by space from annotation value; empty if none)
  def self.get_exercise_methods(course_or_exercise_path)
    path = course_or_exercise_path
    cmd = "java -cp #{Shellwords.escape(classpath)} #{package}.testscanner.TestScanner #{Shellwords.escape(path)}"
    output = `#{cmd}`
    JSON.parse(output).map do |item|
      Hash[item.map {|k,v| [k.underscore.to_sym, v] }]
    end
  end
  
private
  
  def self.package
    "fi.helsinki.cs.tmc"
  end
  
  def self.classpath
    "#{jar_path}:#{project_path}/lib/gson-1.7.1.jar:#{project_path}/lib/junit-4.8.2.jar"
  end
end
