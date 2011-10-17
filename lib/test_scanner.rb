require 'tmc_javalib'
require 'digest'
require 'find'

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
    files = []
    Find.find(path + "/test") do |file|
      files << file unless File.directory?(file)
    end
    files.sort.each do |file|
      hash = Digest::MD5.hexdigest(hash + file + IO.read(file)) unless File.directory?(file)
    end
    hash
  end
end

