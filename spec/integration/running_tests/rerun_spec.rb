require 'spec_helper'

describe RemoteSandboxForTesting, type: :request, integration: true do
  include GitTestActions

  describe "rerunning an old submission" do
    before :each do
      @setup = SubmissionTestSetup.new(exercise_name: 'SimpleExercise')

      @submission = @setup.submission
      @setup.exercise_project.solve_all
      @setup.make_zip
      @submission.return_file = File.read('SimpleExercise.zip')

      @submission.save!
    end

    it "should replace old test case runs" do
      old_tcr = TestCaseRun.create(
        submission: @submission,
        test_case_name: 'SimpleExercise addsub',
        message: 'old run',
        successful: true
      )
      @submission.reload

      RemoteSandboxForTesting.run_submission(@submission)

      expect(@submission.test_case_runs).not_to be_empty
      expect(@submission.test_case_runs).not_to include(old_tcr)
    end

    it "should award new points" do
      @setup.exercise_project.solve_all
      RemoteSandboxForTesting.run_submission(@submission)

      expect(@submission.awarded_points).not_to be_empty
    end

    it "should not delete previously awarded points" do
      old_point = AwardedPoint.create(
        name: 'old point',
        submission: @submission,
        user: @setup.user,
        course: @setup.course
      )
      @submission.reload

      RemoteSandboxForTesting.run_submission(@submission)

      expect(@submission.awarded_points).to include(old_point)
    end
  end
end
