require 'submission_processor'

class SubmissionReprocessorTask
  def initialize
    @processor = SubmissionProcessor.new
  end

  def run
    @processor.reprocess_timed_out_submissions
  end
end
