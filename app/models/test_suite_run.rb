class TestSuiteRun < ActiveRecord::Base
  belongs_to :exercise_return
  has_many :test_case_runs, :dependent => :destroy
  after_create :run_tests

  def run_tests
    TestRunner.test_suite_run self
    Point.check_points self
  end
end
