require 'pathname'
require 'exercise_dir/java_simple'
require 'exercise_dir/java_maven'
require 'exercise_dir/langs'
require 'exercise_dir/makefile_c'

# Holds the path to and metadata about an exercise directory.
# Implemented by project type -specific subclasses.
class ExerciseDir
  def self.get(path)
    dir = try_get(path)
    if dir
      dir
    else
      fail "Not a valid exercise directory: #{path}"
    end
  end

  def self.try_get(path)
    path = Pathname(path)
    cls = exercise_type_impl(path)
    if !cls.nil?
      cls.new(path)
    else
      nil
    end
  end

  def self.exercise_type(path)
    get(path).class.to_s.gsub(/^.*::/, '').underscore.to_sym
  end

  def initialize(path)
    @path = Pathname(path).realpath
  end

  attr_reader :path

  def type
    self.class.name.gsub(/^.*::/, '').underscore
  end

  def name_based_on_path(base_path)
    @path.to_s.sub(/^#{base_path}\//, '').gsub('/', '-')
  end

  def has_tests?
    false
  end

  def self.find_exercise_dirs(path)
    path = Pathname(path)
    TmcLangs.get.find_exercise_dirs(path).map {|dir| ExerciseDir.get(dir) }
  end

  private

  # For now langs packages only java simple and any new formats. -jamo 5/1/2016
  def self.exercise_type_impl(path)
    if (path + 'pom.xml').exist?
      JavaMaven
    elsif (path + 'Makefile').exist? && (path + 'test/').exist?
      MakefileC
    else
      Langs
    end
  end
end
