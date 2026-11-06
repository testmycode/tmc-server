# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sandbox_results_saver'

describe SandboxResultsSaver do
  let(:submission) { FactoryBot.create(:submission, processed: false) }

  def save_finished(test_output)
    SandboxResultsSaver.save_results(submission, 'token' => submission.secret_token, 'status' => 'finished', 'test_output' => test_output)
    submission.reload
  end

  it 'records a pretest error when a finished run has no test output' do
    save_finished('')
    expect(submission).to be_processed
    expect(submission.all_tests_passed).to be(false)
    expect(submission.pretest_error).to start_with('Missing test output.')
  end

  it 'records a pretest error when a finished run has undecodable test output' do
    save_finished('not json')
    expect(submission).to be_processed
    expect(submission.pretest_error).to eq('Unknown error while running tests.')
  end
end
