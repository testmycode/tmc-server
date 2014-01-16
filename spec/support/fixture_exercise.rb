require 'find'
require 'shellwords'

# FIXME: this is a horrible mess. I'm sorry for making it.

# A copy of a fixture exercise.
# Creating an instance of this creates a copy of a fixture exercise combined
# with the template and with the latest tmc-junit-runner.jar added.
# It can then be modified or compiled or whatever by the test.
class FixtureExercise
  include SystemCommands
  extend SystemCommands

  attr_reader :fixture_name
  attr_reader :path

  def self.get(fixture_name, path, options = {})
    case fixture_name
    when 'SimpleExercise'
      FixtureExercise::SimpleExercise.new(path, options)
    when 'MavenExercise'
      FixtureExercise::MavenExercise.new(path, options)
    when 'MakefileC'
      FixtureExercise::MakefileCExercise.new(path, options)
    else
      FixtureExercise.new(fixture_name, path, options)
    end
  end

  def initialize(fixture_name, path, options = {})
    @fixture_name = fixture_name
    @path = File.expand_path(path)
    FileUtils.rm_rf @path if File.exists? @path

    if @path.include?(self.class.fixture_exercises_root)
      raise "Don't create #{self.class} to refer to the fixture. Give it a nonexistent path where it'll create a copy."
    end

    ensure_fixture_clean
    copy_from_fixture
  end

  def fixture_path
    "#{self.class.fixture_exercises_root}/#{fixture_name}"
  end

  def write_metadata(metadata_hash)
    dest = "#{path}/metadata.yml"
    File.open(dest, "wb") { |f| f.write(metadata_hash.to_yaml) }
  end

  def make_zip(options = {})
    options = {
      :src_only => true
    }.merge options

    name = File.basename(@path)

    zip_options = []
    if options[:src_only]
      zip_options << '--include ' + Shellwords.escape("#{name}/src/*")
    end

    Dir.chdir(File.dirname(@path)) do |dir|
      system!("zip -q -0 -r #{zip_path} #{name} #{zip_options.join(' ')}")
    end
  end

  def zip_path
    "#{path}.zip"
  end

  def self.fixture_exercises_root
    "#{::Rails.root}/spec/fixtures/exercises"
  end

private
  def copy_from_fixture
    FileUtils.mkdir_p(path)

    copy_libs
    copy_gitignore
    copy_src
    copy_tests
  end

  def common_files_path
    "#{self.class.fixture_exercises_root}/common_files"
  end

  def copy_libs
    # hard link instead as a small optimization

    FileUtils.rm_rf("#{path}/lib")

    FileUtils.mkdir_p("#{path}/lib")
    Dir.glob("#{common_files_path}/lib/*.jar") do |file|
      FileUtils.ln(file, "#{path}/lib/")
    end
  end

  def copy_gitignore
    gitignore = File.join path, '.gitignore'
    FileUtils.rm_rf gitignore if File.exists? gitignore
    FileUtils.ln("#{common_files_path}/.gitignore", gitignore)
  end

  def copy_src
    FileUtils.cp_r("#{fixture_path}/src", "#{path}/src")
  end

  def copy_tests
    FileUtils.cp_r("#{fixture_path}/test", "#{path}/test")
  end

  def ensure_fixture_clean
    Dir.chdir fixture_path do
      system!("ant clean > /dev/null 2>&1")
    end unless fixture_clean?
  end

  def fixture_clean?
    @@clean_fixtures ||= {}
    @@clean_fixtures[fixture_path] ||= !fixture_contains_class_files?
  end

  def fixture_contains_class_files?
    Find.find(fixture_path) do |file|
      return true if file.end_with?('.class')
    end
    false
  end
end

