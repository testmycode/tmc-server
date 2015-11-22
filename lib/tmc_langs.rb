require 'system_commands'
require 'json'
require 'tempfile'
require 'maven_project'

# Interface to compiling tmc-comet. See also: models/comet_server.rb
class TmcLangs < MavenProject
  def self.get
    @instance ||= TmcLangs.new
  end

  # Get instances via .get instead
  def initialize
    super("#{::Rails.root}/ext/tmc-langs")
  end

  def package_path
    path + 'tmc-langs-cli/target' + package_file_name
  end

  def package_file_name
    "tmc-langs-cli-#{pom_file.artifact_version}.jar"
  end


  def jar_and_lib_paths
    [jar_path] + lib_paths
  end

  def find_exercise_dirs(path)
    temp_file = ::Tempfile.new('langs')
    SystemCommands.sh!('java', '-jar', jar_path, 'find-exercises', path, temp_file.path)
    JSON.parse(File.read(temp_file))
  end

  def scan_exercise(path)
    temp_file = ::Tempfile.new('langs')
    SystemCommands.sh!('java', '-jar', jar_path, 'scan-exercise', path, temp_file.path)
    JSON.parse(File.read(temp_file))
  end

  def get_test_case_methods(exercise_path)
    scan_exercise(exercise_path)['tests']
  end

  def make_stubs(from_dir, to_dir)
    SystemCommands.sh!('java', '-jar', jar_path, 'prepare-stubs', from_dir, to_dir)
  end

  def make_solutions(from_dir, to_dir)
    SystemCommands.sh!('java', '-jar', jar_path, 'prepare-solutions', from_dir, to_dir)
  end
end
