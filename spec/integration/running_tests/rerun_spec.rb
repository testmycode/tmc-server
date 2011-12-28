require 'spec_helper'

describe RemoteSandboxForTesting, :integration => true do
  include GitTestActions

  describe "rerunning an old submission" do
    before :each do
      @setup = SubmissionTestSetup.new(:exercise_name => 'SimpleExercise')
      
      @submission = @setup.submission
      @setup.exercise_project.solve_all
      @setup.make_zip
      @submission.return_file = File.read('SimpleExercise.zip')
      
      @submission.save!
    end
    
    it "should replace old test case runs" do
      old_tcr = TestCaseRun.create(
        :submission => @submission,
        :test_case_name => 'SimpleExercise addsub',
        :message => 'old run',
        :successful => true
      )
      @submission.reload
      
      RemoteSandboxForTesting.run_submission(@submission)
      
      @submission.test_case_runs.should_not be_empty
      @submission.test_case_runs.should_not include(old_tcr)
    end
    
    it "should award new points" do
      @setup.exercise_project.solve_all
      RemoteSandboxForTesting.run_submission(@submission)
      
      @submission.awarded_points.should_not be_empty
    end
    
    it "should not delete previously awarded points" do
      old_point = AwardedPoint.create(
        :name => 'old point',
        :submission => @submission,
        :user => @setup.user,
        :course => @setup.course
      )
      @submission.reload
      
      RemoteSandboxForTesting.run_submission(@submission)
      
      @submission.awarded_points.should include(old_point)
    end
  end
end
