require 'spec_helper'

# FIXME: might not work as expected, tests are not final...
describe RemoteSandboxForTesting, :integration => true do
  specify "running universal_ruby tests" do
    setup = SubmissionTestSetup.new(:exercise_name => 'UniversalRuby')
    submission = setup.submission

    setup.exercise_project.solve_all
    setup.make_zip(src_only: false)
    RemoteSandboxForTesting.run_submission(submission)

    submission.should be_processed
    submission.raise_pretest_error_if_any

    tcr = submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == "Library_hello_world_should_==_\"Hello_world!\"" }
    tcr.should_not be_nil
    tcr.should be_successful

    submission.test_case_runs.should_not be_empty
    tcr = submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'Library_returns_zero_should_==_1' }
    tcr.should_not be_nil
    tcr.should_not be_successful

    submission.awarded_points.count.should == 2
    submission.awarded_points.first.name.should == "1.1"
  end
end

#failPoints %w..
