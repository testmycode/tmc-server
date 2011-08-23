require 'spec_helper'

describe TestRunner do
  describe "when the student's code attempts to delete tests" do
    it "should not leave tests unrun" do
      setup = SubmissionTestSetup.new(:exercise_name => 'malicious/TestDeleter')
      submission = setup.submission
      
      setup.make_zip
      TestRunner.run_submission_tests(submission)
      
      submission.test_case_runs.size.should == 2
      submission.test_case_runs.all?(&:successful).should be_false
      
      case_names = submission.test_case_runs.map(&:test_case_name)
      case_names.sort.should == ['ATest test1', 'BTest test2']
      case_messages = submission.test_case_runs.map(&:message)
      case_messages.should include("java.lang.RuntimeException: Failed to load test class")
    end
  end
end
