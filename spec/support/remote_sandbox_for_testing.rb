require 'fileutils'

module RemoteSandboxForTesting

  @server_pids = nil
  @result_queue = nil
  @server_ports = nil

  def self.server_ports
    @server_ports ||= [FreePorts.take_next, FreePorts.take_next]
  end
  
  # Runs a submission and returns the hash returned by the sandbox server
  def self.run_submission_get_result_hash(submission)
    sandbox = RemoteSandbox.all.first
    sandbox.send_submission(submission, result_queue.receiver_url)
    result_queue.pop
  end
  
  # Runs a submission and asserts the run succeeded.
  # Calls TestRunGrader to insert results and points into the database
  def self.run_submission(submission)
    notification = run_submission_get_result_hash(submission)
    
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
        raise 'No JSON output from test runner' if notification['output'].blank?
        TestRunGrader.grade_results(submission, ActiveSupport::JSON.decode(notification['output']))
      else
        raise 'Unknown status: ' + notification['status']
    end
  end


  def self.init_stubs!
    RemoteSandbox.stub!(:all) do
      if !@server_pids
        @server_pids = server_ports.map {|port| start_server(port) }
        sleep 5 # Wait for servers to start. Haxy, slow, error-prone :(
      end
      server_ports.map {|port| RemoteSandbox.new("http://localhost:#{port}/") }
    end
    
    SiteSetting.all_settings['host_for_remote_sandboxes'] = "localhost:#{result_queue.receiver_port}"
  end
  
  def self.cleanup_after_all_tests!
    if @server_pids
      for server_pid in @server_pids
        Process.kill("KILL", server_pid)
        Process.waitpid(server_pid)
      end
      @server_pids = nil
    end
    
    result_queue.cleanup!
    @result_queue = nil
    
    SiteSetting.reset
  end
  
private

  def self.start_server(port)
    instance_dir = "#{::Rails.root}/tmp/test-sandbox-server/#{port}"
    copy_server_instance(instance_dir)
    
    Process.fork do
      begin
        $stdin.close
        $stdout.reopen("#{instance_dir}/sandbox.log", 'w')
        $stderr.reopen($stdout)
        Dir.chdir instance_dir
        ENV.delete 'BUNDLE_GEMFILE'
        Process.exec("bundle exec rackup --server webrick --port #{port}")
      rescue
        puts e.class.to_s + ": " + e.message
      ensure
        exit!(1)
      end
    end
  end
  
  def self.result_queue
    @result_queue ||= SubmissionResultReceiver.new
  end
  
  def self.copy_server_instance(instance_dir)
    FileUtils.mkdir_p File.dirname(instance_dir)
    FileUtils.rm_rf instance_dir
    FileUtils.cp_r "#{::Rails.root}/ext/tmc-sandbox/web", instance_dir
    
    File.open("#{instance_dir}/site.yml", "w") do |f|
      f.puts "sandbox_files_root: #{::Rails.root}/ext/tmc-sandbox"
    end
  end
  
end

RSpec.configure do |config|
  config.before :each do
    RemoteSandboxForTesting.init_stubs!
  end
  
  config.after :all do
    RemoteSandboxForTesting.cleanup_after_all_tests!
  end
end

