require 'find'
require File.join(File.dirname(File.dirname(__FILE__)), 'fixture_exercise')
require File.join(File.dirname(File.dirname(__FILE__)), 'fixture_exercise', 'simple_exercise')

class FixtureExercise::MavenExercise < FixtureExercise::SimpleExercise
  def initialize(path = 'MavenExercise', options = {})
    options = {
      :fixture_name => 'MavenExercise'
    }.merge(options)
    super(path, options)
  end

  def pom_xml_path
    "#{@path}/pom.xml"
  end

  def java_src_path
    "#{@path}/src/main/java"
  end

  def java_test_path
    "#{@path}/src/test/java"
  end

private
  def copy_from_fixture
    super
    copy_pom_xml
  end

  def copy_libs
    # not for maven projects
  end

  def copy_pom_xml
    FileUtils.cp("#{fixture_path}/pom.xml", pom_xml_path)
  end

  def copy_src
    FileUtils.mkdir_p("#{path}/src")
    FileUtils.cp_r("#{fixture_path}/src/main", "#{path}/src/main")
  end

  def copy_tests
    FileUtils.mkdir_p("#{path}/src")
    FileUtils.cp_r("#{fixture_path}/src/test", "#{path}/src/test")
  end
end