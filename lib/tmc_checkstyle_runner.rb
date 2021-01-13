# frozen_string_literal: true

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
end
