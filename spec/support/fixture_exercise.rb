require 'find'

# A copy of a fixture exercise.
# Creating an instance of this creates a copy of a fixture exercise combined 
# with the template and with the latest tmc-javalib.jar added.
# It can then be modified or compiled or whatever by the test.
class FixtureExercise
  include SystemCommands
  extend SystemCommands

  attr_reader :fixture_name
  attr_reader :path

  def initialize(fixture_name, path = 'SimpleExercise')
    @fixture_name = fixture_name
    @path = File.expand_path(path)
    
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
  
  def make_zip
    name = File.basename(@path)
    Dir.chdir(File.dirname(@path)) do |dir|
      system!("zip -q -0 -r #{name}.zip #{name}")
    end
  end
  
  def self.fixture_exercises_root
    "#{::Rails.root}/spec/fixtures/exercises"
  end
  
private

  def copy_from_fixture
    FileUtils.mkdir_p(path)
    
    FileUtils.mkdir("#{path}/lib")
    Dir.glob("#{common_files_path}/lib/*.jar") do |file|
      FileUtils.ln(file, "#{path}/lib/")
    end
    
    FileUtils.ln("#{common_files_path}/.gitignore", "#{path}/.gitignore")
    FileUtils.ln(TmcJavalib.jar_path, "#{path}/lib/tmc-javalib.jar")
    
    FileUtils.cp_r("#{fixture_path}/src", "#{path}/src")
    FileUtils.cp_r("#{fixture_path}/test", "#{path}/test")
  end
  
  def common_files_path
    "#{self.class.fixture_exercises_root}/common_files"
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

