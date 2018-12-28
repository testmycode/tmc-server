# frozen_string_literal: true

require 'submission_processor'

# In case submission processor task fails, this task will help with sending
# submissions to sandbox. This task uses reverse order in order to avoid
# sending the same submission to sandbox multiple times
class SubmissionLongQueueProcessorTask
  def initialize
    @processor = SubmissionProcessor.new
  end

  def run
    queue = Submission.to_be_reprocessed.where(processing_priority: 0).order(:created_at).reverse_order
    return if queue.length <= 10
    Rails.logger.info "#{queue.length} high priority submissions in queue, trying to process some of them in reverse order..."
    queue.limit(RemoteSandbox.total_capacity).each do |sub|
      Rails.logger.info "Processing submission #{sub} in from the front of the queue since submission queue is so long..."
      @processor.process_submission(sub)
      Rails.logger.info "Processing submission #{sub} done"
    end
  end

  def wait_delay
    1
  end
end
