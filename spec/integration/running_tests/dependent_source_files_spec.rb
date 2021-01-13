# frozen_string_literal: true

require 'spec_helper'

describe RemoteSandboxForTesting, type: :request, integration: true do
  it 'should not have problems compiling a project with source files that depend on each other' do
    skip 'Not working, requires sandbox setup for testing'
    setup = SubmissionTestSetup.new(exercise_name: 'DependentSourceFiles')
    submission = setup.submission

    setup.make_zip
    RemoteSandboxForTesting.run_submission(submission)

    expect(submission.test_case_runs.size).to eq(2)
    expect(submission.test_case_runs.all?(&:successful)).to be_truthy
  end
end
