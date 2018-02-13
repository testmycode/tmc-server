require 'submission_processor'
require 'concurrent'
require 'timeout'

class SubmissionProcessorTask
  def initialize
    @processor = SubmissionProcessor.new
    @pool = Concurrent::ThreadPoolExecutor.new(
      min_threads: [2, Concurrent.processor_count].min,
      max_threads: [2, Concurrent.processor_count].max,
      max_queue: [2, Concurrent.processor_count].max, # Don't want too long queue since it may mess up processing priorities
      fallback_policy: :discard
    )
    @limit = [RemoteSandbox.total_capacity, Concurrent.processor_count, 5].min

    # Since the run method is called repeatedly, we want to keep track of
    # which submissions have already been enqueued
    # Format submission_id: Time
    @submission_enqueued_at = Concurrent::Hash.new
  end

  def run
    process_submissions
  rescue => e
    logger.error("Failed to send submission: #{e}")
  end

  def wait_delay
    0.1
  end

  private

  # Sends submissions to sandbox
  def process_submissions
    if @pool.remaining_capacity <= 0
      logger.warn('Submission processor thread pool queue is full.')
      # Waiting a bit because we don't want to spam this message
      sleep 1
      return
    end
    Submission.to_be_reprocessed.limit(@limit).each do |submission|
      previous_enqueued_at = @submission_enqueued_at[submission.id]
      next if !previous_enqueued_at.nil? && (previous_enqueued_at - Time.current) < 30.seconds
      @submission_enqueued_at[submission.id] = Time.current
      res = Concurrent::Promise.execute(executor: @pool) do
        # We have to spawn a new thread since this does chdirs
        Thread.new do
          # While using timeouts is risky since it can raise an exception on any
          # line, this is still worth the risk -- if this blocks it will hang
          # all submissions.
          Timeout.timeout(30) do
            process_submission(submission)
          end
        end.join
      end

      @submission_enqueued_at[submission.id] = nil unless res
    end
    clean_up_enqueue_times
  end

  def process_submission(submission)
    logger.info "Attempting to process submission #{submission.id}"

    if submission.times_sent_to_sandbox < Submission.max_attempts_at_processing
      @processor.process_submission(submission)
    else
      submission.pretest_error = "Tried to process #{Submission.max_attempts_at_processing} times but failed. This is a system error."
      logger.warn "Submission #{submission.id} marked permanently failed."
      submission.processed = true
      submission.secret_token = nil
      submission.save!
    end
  end

  def clean_up_enqueue_times
    now = Time.current
    @submission_enqueued_at.delete_if { |_key, value| (value - now) > 30.seconds }
  end

  def logger
    @@logger ||= Logger.new(Rails.root.join("log", "submission_processor_task.log"))
  end
end
