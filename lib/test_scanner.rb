require 'tmc_junit_runner'
require 'file_tree_hasher'
require 'test_scanner_cache'

module TestScanner
  extend TestScanner

  # Returns an array of hashes with
  # :class_name => 'UnqualifiedJavaClassName'
  # :method_name => 'testMethodName',
  # :points => ['exercise', 'annotation', 'values']
  #   (split by space from annotation value; empty if none)
  def get_test_case_methods(course, exercise_name, exercise_path)
    hash = FileTreeHasher.hash_file_tree(exercise_path)
    TestScannerCache.get_or_update(course, exercise_name, hash) do
      TmcJunitRunner.get_test_case_methods(exercise_path)
    end
  end
end

