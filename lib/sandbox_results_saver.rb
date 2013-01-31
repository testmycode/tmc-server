
# Saves results from a remote sandbox to the database.
#
# See also: TestRunGrader
module SandboxResultsSaver
  class InvalidTokenError < RuntimeError; end

  def self.save_results(submission, results)
    ActiveRecord::Base.transaction do
      raise InvalidTokenError.new('Invalid or expired token') if results[:token] != submission.secret_token

      submission.all_tests_passed = false
      submission.pretest_error = nil

      submission.stdout = results['stdout']
      submission.stderr = results['stderr']
      submission.vm_log = results['vm_log']

      case results['status']
      when 'timeout'
        submission.pretest_error = 'Timed out. Check your program for infinite loops.'
      when 'failed'
        submission.pretest_error =
          case results['exit_code']
          when '101'
            "Compilation error:\n" + results['test_output']
          when '102'
            "Test compilation error:\n" + results['test_output']
          when '103'
            "Test preparation error:\n" + results['test_output']
          when '137'
            'Program was forcibly terminated most likely due to using too much time or memory.'
          when nil
            "Running the submission failed."
          else
            'Running the submission failed. Exit code: ' + results['exit_code']
          end
      when 'finished'
        begin
          decoded_output = ActiveSupport::JSON.decode(results['test_output'])
        rescue # Most likely because results['output'] was empty
          submission.pretest_error =
            if results['stderr'].include?("java.lang.OutOfMemoryError")
              'Out of memory.'
            else
              'Unknown error while running tests.'
            end
        else
          TestRunGrader.grade_results(submission, decoded_output)
        end
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
