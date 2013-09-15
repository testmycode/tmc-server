require 'spec_helper'

# FIXME: might not work as expected, tests are not final...
describe RemoteSandboxForTesting, :integration => true do
  specify "running makefile_c tests" do
    setup = SubmissionTestSetup.new(:exercise_name => 'MakefileC')
    submission = setup.submission

    setup.exercise_project.solve_all
    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    submission.should be_processed
    submission.raise_pretest_error_if_any

    tcr = submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'my-suite test_bar' }
    tcr.should_not be_nil
    tcr.should_not be_successful

    submission.test_case_runs.should_not be_empty
    tcr = submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'my-suite test_foo' }
    tcr.should_not be_nil
    tcr.should be_successful

    submission.awarded_points.count.should == 3
    submission.awarded_points.first.name.should == "point1"
  end

  specify "C compilation failures" do
    setup = SubmissionTestSetup.new(:exercise_name => 'MakefileC')
    submission = setup.submission

    setup.exercise_project.introduce_compilation_error
    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    submission.should be_processed
    submission.pretest_error.should include('Compilation error')
  end
end