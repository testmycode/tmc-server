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

  def package_file_name
    "tmc-langs-cli-#{pom_file.artifact_version}.jar"
  end

  def package_path
    path + 'tmc-langs-cli/target' + package_file_name
  end

  def jar_path
    path + 'tmc-langs-cli/target' + package_file_name
  end

  def find_exercise_dirs(path)
    temp_file = ::Tempfile.new('langs')
    exec('find-exercises', path, temp_file.path)
    JSON.parse(File.read(temp_file))
  end

  def scan_exercise(path)
    temp_file = ::Tempfile.new('langs')
    exec("scan-exercise", path, temp_file.path)
    JSON.parse(File.read(temp_file))
  end

  def get_test_case_methods(exercise_path)
    scan_exercise(exercise_path)['tests']
  end

  def make_stubs(from_dir, to_dir)
    exec("prepare-stubs", from_dir, to_dir)
  end

  def make_solutions(from_dir, to_dir)
    exec("prepare-solutions", from_dir, to_dir)
  end

  def get_exercise_config(from_dir)
    temp_file = ::Tempfile.new('langs')
    exec("get-exercise-packaging-configuration", from_dir, temp_file.path)
    JSON.parse(File.read(temp_file))
  end

  private
  def exec(cmd, exercise_path, output_path)
    SystemCommands.sh!('java', '-jar', jar_path, cmd, '--exercisePath', exercise_path, '--outputPath', output_path)
  end
end
