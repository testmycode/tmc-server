require 'spec_helper'

describe RemoteSandboxForTesting, :integration => true do
  specify "running maven tests" do
    setup = SubmissionTestSetup.new(:exercise_name => 'MavenExercise')
    submission = setup.submission

    setup.exercise_project.solve_sub
    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    submission.should be_processed
    submission.raise_pretest_error_if_any

    tcr = submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'SimpleTest testSubtract' }
    tcr.should_not be_nil
    tcr.should be_successful

    submission.test_case_runs.should_not be_empty
    tcr = submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'SimpleTest testAdd' }
    tcr.should_not be_nil
    tcr.should_not be_successful

    submission.awarded_points.count.should == 1
    submission.awarded_points.first.name.should == 'justsub'
  end
end
