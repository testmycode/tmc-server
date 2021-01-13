# frozen_string_literal: true

require 'file_tree_hasher'
require 'test_scanner_cache'

# Scans for test cases in an exercise directory.
#
# Called by CourseRefresher. Uses TMC-Langs
module TestScanner
  extend TestScanner

  def get_test_case_methods(course, exercise_name, exercise_path)
    hash = FileTreeHasher.hash_file_tree(exercise_path)
    TestScannerCache.get_or_update(course, exercise_name, hash) do
      TmcLangs.get.get_test_case_methods(exercise_path)
    end
  end
end
