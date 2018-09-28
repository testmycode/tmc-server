# frozen_string_literal: true

require 'spec_helper'

# FIXME: might not work as expected, tests are not final...
describe RemoteSandboxForTesting, type: :request, integration: true do
  specify 'running makefile_c tests' do
    setup = SubmissionTestSetup.new(exercise_name: 'MakefileC')
    submission = setup.submission

    setup.exercise_project.solve_all
    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    expect(submission).to be_processed
    submission.raise_pretest_error_if_any

    tcr = submission.test_case_runs.to_a.find { |tcr| tcr.test_case_name == 'my-suite test_bar' }
    expect(tcr).not_to be_nil
    expect(tcr).not_to be_successful

    expect(submission.test_case_runs).not_to be_empty
    tcr = submission.test_case_runs.to_a.find { |tcr| tcr.test_case_name == 'my-suite test_foo' }
    expect(tcr).not_to be_nil
    expect(tcr).to be_successful

    expect(submission.awarded_points.count).to eq(3)
    expect(submission.awarded_points.map(&:name)).to include('point1')
  end

  specify 'C compilation failures' do
    setup = SubmissionTestSetup.new(exercise_name: 'MakefileC')
    submission = setup.submission

    setup.exercise_project.introduce_compilation_error
    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    expect(submission).to be_processed
    expect(submission.pretest_error).to include('Compilation error')
  end
end
