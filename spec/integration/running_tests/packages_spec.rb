require 'spec_helper'

describe TestRunnerIntegrationSetup, :test_runner => true do
  describe "when the exercise has source and test classes in packages" do
    it "should have no problems" do
      setup = SubmissionTestSetup.new(:exercise_name => 'ExerciseWithPackages')
      submission = setup.submission
      
      setup.make_zip
      TestRunnerIntegrationSetup.run_submission_tests(submission)
      
      submission.test_case_runs.size.should == 1
      
      tcr = submission.test_case_runs.first
      tcr.test_case_name.should == 'pkg.PackagedTest testPackagedMethod'
      tcr.should be_successful
      
      submission.awarded_points.first.name.should == 'packagedtest'
    end
  end
end
