class TestSuiteRun < ActiveRecord::Base
  belongs_to :submission
  has_many :test_case_runs, :dependent => :destroy
  after_create :run_tests

  def all_successful?
    @all_successful |= test_case_runs.map(&:success?).all?
  end

  def run_tests
    TestRunner.test_suite_run self
    Point.check_points self
  end
end
