require 'pathname'

# Holds the path to and metadata about an exercise directory
class ExerciseDir
  def initialize(path)
    @path = Pathname(path).realpath
  end
  
  attr_reader :path
  
  def name_based_on_path(base_path)
    @path.to_s.sub(/^#{base_path}\//, '').gsub('/', '-')
  end
  
  def library_jars
    result = []
    (@path + 'lib').find do |file|
      result << file if file.file? && file.extname == '.jar'
    end
    result
  end


  def self.find_exercise_dirs(path)
    path = Pathname(path)
    
    result = []
    
    path.find do |subpath|
      if looks_like_exercise_path? subpath
        if subpath.basename.to_s.include?('-')
          raise "Exercise directory #{subpath.basename} has a dash (-), which is not allowed"
        end
        
        result << ExerciseDir.new(subpath)
      end
    end
    
    result
  end
  
private
  def self.looks_like_exercise_path?(path)
    path.directory? && (path + 'src').exist? && (path + 'test').exist?
  end
end

