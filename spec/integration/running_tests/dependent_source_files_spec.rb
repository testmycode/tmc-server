require 'spec_helper'

describe TestRunnerIntegrationSetup, :integration => true do
  it "should not have problems compiling a project with source files that depend on each other" do
    setup = SubmissionTestSetup.new(:exercise_name => 'DependentSourceFiles')
    submission = setup.submission
    
    setup.make_zip
    TestRunnerIntegrationSetup.run_submission_tests(submission)
    
    submission.test_case_runs.size.should == 2
    submission.test_case_runs.all?(&:successful).should be_true
  end
end
