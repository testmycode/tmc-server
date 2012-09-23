require 'system_commands'
require 'maven_project'

# Interface to compiling tmc-comet.
class TmcComet < MavenProject
  def self.get
    @instance ||= TmcComet.new
  end

  # Get instances via .get instead
  def initialize
    super("#{::Rails.root}/ext/tmc-comet")
  end
end