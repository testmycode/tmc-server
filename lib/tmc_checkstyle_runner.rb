require 'shellwords'
require 'maven_project'

# Interface to tmc-junit-runner.
class TmcCheckstyleRunner < MavenProject
  def self.get
    @instance ||= TmcCheckstyleRunner.new
  end

  # Get instances via .get instead
  def initialize
    super("#{::Rails.root}/ext/tmc-checkstyle-runner")
  end

  def jar_and_lib_paths
    [jar_path] + lib_paths
  end

  def parse_test_scanner_output(output)
    JSON.parse(output).map do |item|
      Hash[item.map {|k,v| [k.underscore.to_sym, v] }]
    end
  end
end

