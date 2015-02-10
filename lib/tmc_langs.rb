require 'shellwords'
require 'maven_project'

class TmcLangs < MavenProject
  def self.get
    @instance ||= TmcLangs.new
  end

  # Get instances via .get instead
  def initialize
    super("#{::Rails.root}/ext/tmc-langs")
  end

  def jar_and_lib_paths
    [jar_path] + lib_paths
  end
end
