# frozen_string_literal: true

require 'spec_helper'

describe RemoteSandboxForTesting, type: :request, integration: true do
  describe 'when the exercise has source and test classes in packages' do
    skip 'Not working, requires sandbox setup for testing'
    it 'should have no problems' do
      setup = SubmissionTestSetup.new(exercise_name: 'ExerciseWithPackages')
      submission = setup.submission

      setup.make_zip
      RemoteSandboxForTesting.run_submission(submission)

      expect(submission.test_case_runs.size).to eq(1)

      tcr = submission.test_case_runs.first
      expect(tcr.test_case_name).to eq('pkg.PackagedTest testPackagedMethod')
      expect(tcr).to be_successful

      expect(submission.awarded_points.first.name).to eq('packagedtest')
    end
  end
end
