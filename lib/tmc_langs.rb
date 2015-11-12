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

  def pom_path
    path + 'tmc-langs-cli/' +  'pom.xml'
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

end
