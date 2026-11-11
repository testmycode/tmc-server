# typed: strict
# frozen_string_literal: true

require 'submission_processor'

class SubmissionProcessorTask
  extend T::Sig
  sig { void }
  def initialize
    @processor = T.let(SubmissionProcessor.new, SubmissionProcessor)
  end

  sig { void }
  def run
    @processor.process_some_submissions
  end

  sig { returns(Float) }
  def wait_delay
    0.1
  end
end
