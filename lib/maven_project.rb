require 'pathname'
require 'system_commands'
require 'maven_pom_file'

class MavenProject
  def initialize(path)
    @path = Pathname(path)
  end

  attr_reader :path

  def version
    pom_file.artifact_version
  end

  def lib_paths
    @lib_paths ||= build_classpath.split(':').map {|path| Pathname(path) }
  end

  def pom_file
    @pom_file ||= MavenPomFile.new(pom_path)
  end

  def pom_path
    path + 'pom.xml'
  end

  def package_path
    path + 'target' + package_file_name
  end

  def package_file_name
    "#{pom_file.artifact_id}-#{pom_file.artifact_version}.#{pom_file.packaging}"
  end

  def compiled?
    File.exists? package_path
  end

  def compile!
    Dir.chdir(path) do
      SystemCommands.sh!('mvn', '-q', 'package')
    end
  end

  def clean_compiled_files!
    Dir.chdir(path) do
      SystemCommands.sh!('mvn', '-q', 'clean')
    end
  end

protected

  def build_classpath
    file_path = "misc/#{pom_file.artifact_id}-build-classpath"
    begin
      too_old = FileStore.mtime(file_path) > File.mtime(package_path)
    rescue # no such file most likely
      too_old = true
    end

    if !too_old
      result = FileStore.try_get(file_path)
    else
      result = nil
    end

    if !result
      output = nil
      Dir.chdir(path) do
        output = `mvn org.apache.maven.plugins:maven-dependency-plugin:2.4:build-classpath`
      end
      if output =~ /\[INFO\] Dependencies classpath:\n(.*)\n/
        result = $1.strip
        FileStore.put(file_path, result)
      else
        raise "Failed to get build classpath of tmc-junit-runner."
      end
    end
    result
  end
end