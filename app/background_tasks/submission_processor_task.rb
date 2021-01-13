# frozen_string_literal: true

require 'submission_processor'

class SubmissionProcessorTask
  def initialize
    @processor = SubmissionProcessor.new
  end

  def run
    @processor.process_some_submissions
  end

  def wait_delay
    0.1
  end
end
