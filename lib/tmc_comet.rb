require 'system_commands'
require 'maven_project'

# Interface to compiling tmc-comet. See also: models/comet_server.rb
class TmcComet < MavenProject
  def self.get
    @instance ||= TmcComet.new
  end

  # Get instances via .get instead
  def initialize
    super("#{::Rails.root}/ext/tmc-comet/tmc-comet-server")
  end

  def compile!
    # This needs to be mvn install'ed as opposed to merely packaged because
    # the WAR file is loaded dynamically.
    Dir.chdir(path.parent) do
      SystemCommands.sh!('mvn', '-q', 'install', '-Dmaven.test.skip=true')
    end
  end

  def package_file_name
    super.sub(/\.#{pom_file.packaging}/, "-all.#{pom_file.packaging}")
  end
end
