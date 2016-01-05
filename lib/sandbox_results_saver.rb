# Saves results from a remote sandbox to the database.
#
# See also: TestRunGrader
module SandboxResultsSaver
  class InvalidTokenError < RuntimeError; end

  def self.save_results(submission, results)
    ActiveRecord::Base.transaction do
      fail InvalidTokenError.new('Invalid or expired token') if results['token'] != submission.secret_token

      maybe_tranform_results_from_tmc_langs!(results)

      submission.all_tests_passed = false
      submission.pretest_error = nil

      submission.stdout = results['stdout']
      submission.stderr = results['stderr']
      submission.vm_log = results['vm_log']
      submission.valgrind = results['valgrind']
      submission.validations = results['validations']

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
          when '104'
            "Checkstyle runner error:\n" + results['test_output']
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
        fail 'Unknown status: ' + results['status']
      end

      submission.secret_token = nil
      submission.processed = true
      submission.processing_completed_at = Time.now
      submission.save!
    end
  end

  private

  def self.maybe_tranform_results_from_tmc_langs!(results)
    # extract data from this -- it's JSON man
    if results.has_key? 'test_output'
      begin
        test_output = JSON.parse results["test_output"]
      rescue JSON::ParserError
        results['test_output'] = {}
        results['status'] = 'finished'
        results['exit_code'] = 'faulty-json'
        return
      end
      case test_output['status']
      when 'COMPILE_FAILED'
        results['status'] = 'failed'
        results['exit_code'] = '101'
      when 'TESTS_FAILED'
        output = test_output['testResults'].map do |result|
          result['className'], result['methodName'] = result['name'].split(/\s/)
          result['message'] = result['errorMessage']
          result['backtrace'] = result['backtrace'].join("\n") if result.has_key? 'backtrace'
          result['pointNames'] = result['points'] if result.has_key? 'points'
          result['status'] = result['passed'] ? 'PASSED' : 'FAILED'
          result
        end
        results['old_test_output'] = results['test_output']
        results['test_output'] = output
      when 'PASSED'
        output = test_output['testResults'].map do |result|
          result['className'], result['methodName'] = result['name'].split(/\s/)
          result['message'] = result['errorMessage']
          result['backtrace'] = result['backtrace'].join("\n") if result.has_key? 'backtrace'
          result['pointNames'] = result['points'] if result.has_key? 'points'
          result['status'] = result['passed'] ? 'PASSED' : 'FAILED'
          result
        end
        results['old_test_output'] = results['test_output']
        results['test_output'] = output
      else
        require 'pry'
        binding.pry
      end

      if test_output.has_key? 'logs'
        results['stdout'] += test_output['logs']['stdout'].pack('c*') if test_output['logs'].has_key? 'stdout'
        results['stderr'] += test_output['logs']['stderr'].pack('c*') if test_output['logs'].has_key? 'stderr'
      end
    else
      require 'pry'
      binding.pry
    end

    # TODO: figure out
    #results["valgrind"]
    #results["validations"]
  end

  def self.decode_test_output(test_output, stderr)
    likely_out_of_memory = stderr.include?('java.lang.OutOfMemoryError')

    if test_output.blank?
      if likely_out_of_memory
        return 'Out of memory.'
      else
        return 'Missing test output. Did you terminate your program with an exit() command?'
      end
    end

    begin
      result = if test_output.is_a?(Enumerable)
                 test_output
               else
                 ActiveSupport::JSON.decode(test_output)
               end
      fail unless result.is_a?(Enumerable)
      result
    rescue
      require 'pry'
      binding.pry
      if likely_out_of_memory
        'Out of memory.'
      else
        'Unknown error while running tests.'
      end
    end
  end
end
