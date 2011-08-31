require 'digest'

module TestScanner
  extend TestScanner

  #TODO: for efficiency, take multiple paths and get results in one run
  
  # Returns an array of hashes with
  # :class_name => 'UnqualifiedJavaClassName'
  # :method_name => 'testMethodName',
  # :points => ['exercise', 'annotation', 'values']
  #   (split by space from annotation value; empty if none)
  def get_test_case_methods(course_or_exercise_path)
    path = course_or_exercise_path
    cache_key = "TMC.TestScanner:" + checksum_test_files(path)
    
    cache.fetch(cache_key) do
      TmcJavalib.get_test_case_methods(path)
    end
  end
  
protected
  def cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
  
  def checksum_test_files(path)
    hash = Digest::MD5.hexdigest('')
    Dir.glob(path + "/test/**").sort.each do |filename|
      hash = Digest::MD5.hexdigest(hash + IO.read(filename)) unless File.directory?(filename)
    end
    hash
  end
end

