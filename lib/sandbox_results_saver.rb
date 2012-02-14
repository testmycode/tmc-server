
# Saves results from a remote sandbox to the database.
module SandboxResultsSaver
  class InvalidTokenError < RuntimeError; end

  def self.save_results(submission, results)
    ActiveRecord::Base.transaction do
      raise InvalidTokenError.new('Invalid or expired token') if results[:token] != submission.secret_token

      submission.all_tests_passed = false
      submission.pretest_error = nil

      case results['status']
      when 'timeout'
        submission.pretest_error = 'Timed out. Check your program for infinite loops.'
      when 'failed'
        submission.pretest_error =
          case results['exit_code']
          when '101'
            "Compilation error:\n" + results['output']
          when '102'
            "Test compilation error:\n" + results['output']
          when '137'
            'Program was forcibly terminated most likely due to using too much time or memory.'
          else
            'Running the submission failed. Exit code: ' + results['exit_code']
          end
      when 'finished'
        TestRunGrader.grade_results(submission, ActiveSupport::JSON.decode(results['output']))
      else
        raise 'Unknown status: ' + results['status']
      end
      
      submission.secret_token = nil
      submission.processed = true
      submission.processing_completed_at = Time.now
      submission.save!
    end
  end
end
