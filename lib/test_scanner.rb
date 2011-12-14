require 'tmc_junit_runner'

module TestScanner
  extend TestScanner

  # Returns an array of hashes with
  # :class_name => 'UnqualifiedJavaClassName'
  # :method_name => 'testMethodName',
  # :points => ['exercise', 'annotation', 'values']
  #   (split by space from annotation value; empty if none)
  def get_test_case_methods(course_or_exercise_path)
    TmcJunitRunner.get_test_case_methods(course_or_exercise_path)
  end
end

