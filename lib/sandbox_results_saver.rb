
# Saves results from a remote sandbox to the database.
#
# See also: TestRunGrader
module SandboxResultsSaver
  class InvalidTokenError < RuntimeError; end

  def self.save_results(submission, results)
    ActiveRecord::Base.transaction do
      raise InvalidTokenError.new('Invalid or expired token') if results['token'] != submission.secret_token

      submission.all_tests_passed = false
      submission.pretest_error = nil

      submission.stdout = results['stdout']
      submission.stderr = results['stderr']
      submission.vm_log = results['vm_log']
      submission.valgrind = results['valgrind']
      submission.validations = results['validations']

      if not submission.valgrind.blank?
        submission.pretest_error = 'Errors in Valgrind check. See Valgrind log below.'
      end
#      if not submission.validations.blank?
#        submission.pretest_error = 'Errors in validations - see log below!.'
#      end

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
            'Program was forcibly terminated, most likely due to using too much time or memory.'
          when nil
            'Running the submission failed.'
          else
            'Running the submission failed. Exit code: ' + results['exit_code'] + ' (did you use an exit() command?)'
          end
      when 'finished'
        decoded_output = decode_test_output(results['test_output'], results['stderr'])
        if decoded_output.is_a?(Enumerable)
          TestRunGrader.grade_results(submission, decoded_output)
        else
          submission.pretest_error = decoded_output.to_s
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

private
  def self.decode_test_output(test_output, stderr)
    likely_out_of_memory = stderr.include?("java.lang.OutOfMemoryError")

    if test_output.blank?
      if likely_out_of_memory
        return 'Out of memory.'
      else
        return 'Missing test output. Did you terminate your program with an exit() command?'
      end
    end

    begin
      result = ActiveSupport::JSON.decode(test_output)
      raise unless result.is_a?(Enumerable)
      result
    rescue
      if likely_out_of_memory
        'Out of memory.'
      else
        'Unknown error while running tests.'
      end
    end
  end
end
