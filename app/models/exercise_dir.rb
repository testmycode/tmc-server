require 'pathname'
require 'exercise_dir/java_simple'
require 'exercise_dir/java_maven'

# Holds the path to and metadata about an exercise directory.
# Implemented by subclasses.
class ExerciseDir
  def self.get(path)
    dir = try_get(path)
    if dir
      dir
    else
      raise "Not a valid exercise directory: #{path}"
    end
  end

  def self.try_get(path)
    path = Pathname(path)
    cls = exercise_type_impl(path)
    if cls != nil
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
    
    result = []
    
    path.find do |subpath|
      Find.prune if !subpath.directory? || irrelevant_directory?(subpath)

      cls = exercise_type_impl(subpath)
      if cls != nil
        if subpath.basename.to_s.include?('-')
          raise "Exercise directory #{subpath.basename} has a dash (-), which is not allowed"
        end

        result << cls.new(subpath)
      end
    end
    
    result
  end
  
private
  def self.irrelevant_directory?(path)
    path.directory? && (
      path.children.map(&:basename).map(&:to_s).include?('.tmcignore') ||
      path.basename.to_s.start_with?('.')
    )
  end

  def self.exercise_type_impl(path)
    if (path + 'pom.xml').exist?
      JavaMaven
    elsif (path + 'src').exist? && (path + 'test').exist?
      JavaSimple
    else
      nil
    end
  end
end

