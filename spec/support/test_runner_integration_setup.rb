require 'mimic'
require 'submission_packager'
require 'test_run_grader'

# Sends a submission to a sandbox and uses mimic to catch the results
module TestRunnerIntegrationSetup
  
  def self.run_submission_tests(submission)
    ensure_notify_server_inited
    sandbox = RemoteSandbox.random
    sandbox.send_submission(submission, notify_url)
    notification = @notify_queue.pop
    case notification['status']
      when 'timeout'
        raise 'Timed out'
      when 'failed'
        if notification['exit_code'] == '101'
          raise "Compilation error:\n" + notification['output']
        else
          raise 'Running the submission failed. Exit code: ' + notification['exit_code'].to_s
        end
      when 'finished'
        TestRunGrader.grade_results(submission, ActiveSupport::JSON.decode(notification['output']))
      else
        raise 'Unknown status: ' + notification['status']
    end
  end
  
  def self.notify_url
    'http://localhost:3004/notify'
  end
  
  def self.cleanup!
    Mimic.cleanup!
    @notify_queue = nil
  end
  
private
  def self.ensure_notify_server_inited
    if !@notify_queue
      @notify_queue = Queue.new
      notify_queue = @notify_queue # put in closure, blocks below have different `self`
      Mimic.mimic(:port => 3004, :fork => true) do
        post("/notify") do
          notify_queue << params
          [200, {}, ["OK"]]
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.after(:all) do
    TestRunnerIntegrationSetup.cleanup!
  end
end

