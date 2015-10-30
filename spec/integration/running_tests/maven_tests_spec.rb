require 'spec_helper'

describe RemoteSandboxForTesting, type: :request, integration: true, network: true do
  specify 'running maven tests' do
    setup = SubmissionTestSetup.new(exercise_name: 'MavenExercise')
    submission = setup.submission

    setup.exercise_project.solve_sub
    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    expect(submission).to be_processed
    submission.raise_pretest_error_if_any

    tcr = submission.test_case_runs.to_a.find { |tcr| tcr.test_case_name == 'SimpleTest testSubtract' }
    expect(tcr).not_to be_nil
    expect(tcr).to be_successful

    expect(submission.test_case_runs).not_to be_empty
    tcr = submission.test_case_runs.to_a.find { |tcr| tcr.test_case_name == 'SimpleTest testAdd' }
    expect(tcr).not_to be_nil
    expect(tcr).not_to be_successful

    expect(submission.awarded_points.count).to eq(1)
    expect(submission.awarded_points.first.name).to eq('justsub')
  end
end
