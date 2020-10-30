# frozen_string_literal: true

# Saves results from a remote sandbox to the database.
#
# See also: TestRunGrader
module SandboxResultsSaver
  class InvalidTokenError < RuntimeError; end

  def self.save_results(submission, results)
    ActiveRecord::Base.transaction do
      raise InvalidTokenError, 'Invalid or expired token' if results['token'] != submission.secret_token
      
      submission.all_tests_passed = false
      # Rails.logger.info(results)
      # Set sandbox stdout and stderr
      submission.stdout = results['stdout']
      submission.stderr = results['stderr']
      submission.vm_log = results['vm_log']
      submission.valgrind = results['valgrind']
      submission.validations = results['validations']
      
      tmc_langs_response = decode_test_output(results['test_output'])
      handle_tmc_langs_output(submission, tmc_langs_response)
      

      case results['status']
      when 'timeout'
        submission.pretest_error = 'Timed out. Check your program for infinite loops.'
      when 'failed'
        submission.pretest_error =
          case results['exit_code']
          when '110'
            "Executing tests with tmc-langs-rust failed:\n" + results['test_output']
          when '137'
            'Program was forcibly terminated, most likely due to using too much time or memory.'
          when nil
            'Running the submission failed.'
          else
            'Running the submission failed. Exit code: ' + results['exit_code'] + ' (did you use an exit() command?)'
          end
          if submission.stdout.include?('Temporary failure in name resolution: Unknown host maven.mooc.fi')
            submission.pretest_error = "Unable to run tests because this course's teacher has not configured this exercise template correctly.\nPlease contact your teacher so that they can fix the template and rerun your submission.\nIf your solution is correct, you'll get the points from this exercise once the teacher reruns your submission."
          end

      when 'finished'
        # decoded_output = decode_test_output(results['test_output'])
        # if decoded_output.is_a?(Enumerable)
        TestRunGrader.grade_results(submission, tmc_langs_response)
        # else
        #   submission.pretest_error = decoded_output.to_s
        # end
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
    def self.handle_tmc_langs_output(submission, test_output)
      if test_output.key? 'logs'
        if test_output['logs'].key? 'stdout'
          submission.stdout = test_output['logs']['stdout']
        end
        if test_output['logs'].key? 'stderr'
          submission.stderr = test_output['logs']['stderr']
        end
      end

      case test_output['status']
      when 'COMPILE_FAILED'
        submission.pretest_error = "Compilation error:\n" + test_output['logs'].map do |k, v| "#{k}: #{v}" end.join("\n")
      when 'GENERIC_ERROR'
        submission.pretest_error = "Generic error:\n" + test_output['logs'].map do |k, v| "#{k}: #{v}" end.join("\n")
      when 'TESTS_FAILED', 'PASSED'
        submission.pretest_error = nil
      when 'TESTRUN_INTERRUPTED'
        submission.pretest_error = "Missing test output. Did you terminate your program with an exit() command?\nAlso make sure your program did not run out of memory.\nFor example excessive printing (thousands of lines) may cause this."
      else
        raise "Unknown result type from tmc-langs: #{test_output}"
      end
    end

    def self.decode_test_output(test_output)
      if test_output.blank?
        return 'Missing test output. Did you terminate your program with an exit() command? Also make sure your program did not run out of memory. For example excessive printing (thousands of lines) may cause this.'
      end

      begin
        result = if test_output.is_a?(Enumerable)
          test_output
        else
          ActiveSupport::JSON.decode(test_output)
        end
        raise unless result.is_a?(Enumerable)
        result
      rescue StandardError
        'Unknown error while running tests.'
      end
    end
end
