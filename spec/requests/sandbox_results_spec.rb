# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Sandbox result callback', type: :request do
  let(:submission) { FactoryBot.create(:submission, processed: false) }
  let!(:point) { FactoryBot.create(:available_point, exercise: submission.exercise) }
  let(:test_output) do
    {
      'status' => 'PASSED',
      'testResults' => [{ 'name' => 'FooTest', 'successful' => true, 'points' => [point.name], 'message' => '' }],
      'logs' => {}
    }.to_json
  end

  def post_result(extra_params)
    post "/submissions/#{submission.id}/result", params: { 'status' => 'finished', 'test_output' => test_output }.merge(extra_params)
  end

  def expect_rejected
    expect(response).to have_http_status(:unauthorized)
    expect(AwardedPoint.count).to eq(0)
    expect(submission.reload.test_case_runs).to be_empty
  end

  it 'rejects a result without a token' do
    post_result({})
    expect_rejected
    expect(submission).not_to be_processed
  end

  it 'rejects a result with a wrong token' do
    post_result('token' => 'wrong')
    expect_rejected
    expect(submission).not_to be_processed
  end

  it 'rejects a result for an already processed submission' do
    token = submission.secret_token
    submission.update!(processed: true)
    post_result('token' => token)
    expect_rejected
  end

  it 'rejects a result without a token for a submission whose token was cleared' do
    submission.update!(secret_token: nil, processed: true)
    post_result({})
    expect_rejected
  end

  it 'rejects a blank token while the submission has none' do
    submission.update!(secret_token: nil)
    post_result('token' => '')
    expect_rejected
  end

  it 'saves the result and awards points with the valid token' do
    post_result('token' => submission.secret_token)
    expect(response).to have_http_status(:ok)
    submission.reload
    expect(submission).to be_processed
    expect(submission.secret_token).to be_nil
    expect(submission.all_tests_passed).to be(true)
    expect(AwardedPoint.where(submission: submission).map(&:name)).to eq([point.name])
  end

  it 'accepts the rotated token after a rerun' do
    old_token = submission.secret_token
    submission.set_to_be_reprocessed!
    post_result('token' => old_token)
    expect(response).to have_http_status(:unauthorized)
    post_result('token' => submission.reload.secret_token)
    expect(response).to have_http_status(:ok)
    expect(submission.reload).to be_processed
  end
end
