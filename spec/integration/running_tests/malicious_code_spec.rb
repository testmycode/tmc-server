require 'spec_helper'

describe RemoteSandboxForTesting, :integration => true do
  def setup_and_run(exercise_name)
    setup = SubmissionTestSetup.new(:exercise_name => exercise_name)
    submission = setup.submission

    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    setup
  end

  describe "when the student's code attempts to delete tests" do
    it "should not leave tests unrun" do
      setup = setup_and_run('malicious/TestDeleter')
      submission = setup.submission
      
      submission.test_case_runs.size.should == 2
      submission.test_case_runs.should_not be_all(&:successful)
      submission.test_case_runs.should be_any(&:successful)
      
      case_names = submission.test_case_runs.map(&:test_case_name)
      case_names.sort.should == ['ATest test1', 'BTest test2']
      case_messages = submission.test_case_runs.map(&:message)
      case_messages.should include("Failed to run test.")
    end
  end

  describe "when the student's code does System.exit(0)" do
    it "should report this as a likely cause for missing test results" do
      setup = setup_and_run('malicious/Exit0')
      submission = setup.submission

      submission.pretest_error.should == 'Invalid or missing test output. Did you terminate your program with an exit() command?'
    end
  end

  describe "when the student's code does System.exit(1)" do
    it "should report this as a likely cause for missing test results" do
      setup = setup_and_run('malicious/Exit1')
      submission = setup.submission

      submission.pretest_error.should include(' (did you use an exit() command?)')
    end
  end
end
