# typed: false
# frozen_string_literal: true

require 'sandbox_results_saver'

class RemoteSandboxForTesting
  @result_queue = nil

  # Runs a submission and asserts the run succeeded, then calls SandboxResultsSaver.
  def self.run_submission(submission)
    submission.randomize_secret_token if submission.secret_token.nil?

    sandbox = RemoteSandbox.all.first
    sandbox.send_submission(submission, result_queue.receiver_url)
    results = result_queue.pop
    SandboxResultsSaver.save_results(submission, results)
  end

  private_class_method def self.result_queue
    @result_queue ||= SubmissionResultReceiver.new
  end
end
