require 'pathname'
require 'system_commands'
require 'maven_pom_file'

class MavenProject
  def initialize(path)
    @path = Pathname(path)
  end

  attr_reader :path

  def name
    pom_file.artifact_id
  end

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

  def make_rake_tasks(dsl_obj, task_namespace)
    project = self
    dsl_obj.instance_eval do
      file project.jar_path => FileList["#{project.path}/**/*.java"] do
        puts "Compiling #{project.package_path} ..."
        begin
          project.compile!
        rescue
          puts "*** Failed to compile #{project.name} ***"
          puts "  Have you done `git submodule update --init`?"
          puts
          raise
        end
        # In case it was already compiled and ant had nothing to do,
        # we'll touch the jar file to make it newer than the deps.
        FileUtils.touch(project.package_path) if File.exists?(project.package_path)
      end

      namespace task_namespace do
        desc "Compiles #{project.package_path}"
        task :compile => project.package_path

        desc "Cleans #{project.package_path}"
        task :clean do
          project.clean_compiled_files!
        end

        desc "Forces a recompile of #{project.package_path}"
        task :recompile => [:clean, :compile]
      end

      desc "Compiles #{project.package_path}"
      task task_namespace => '#{task_namespace}:compile'

      # Have rake spec ensure this is compiled
      task :spec => project.jar_path
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