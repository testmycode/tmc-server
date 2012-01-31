require 'fileutils'

class RemoteSandboxForTesting

  @server_pids = nil
  @result_queue = nil
  @server_ports = nil

  def self.server_ports
    # FIXME: can have only one at a time because UML performs file locking :/
    @server_ports ||= [FreePorts.take_next]
  end
  
  # Runs a submission and asserts the run succeeded, then calls SandboxResultsSaver.
  def self.run_submission(submission)
    submission.randomize_secret_token if submission.secret_token == nil
  
    sandbox = RemoteSandbox.all.first
    sandbox.send_submission(submission, result_queue.receiver_url)
    results = result_queue.pop
    SandboxResultsSaver.save_results(submission, results)
  end


private
  def self.init_stubs!
    RemoteSandbox.stub!(:all) do
      if !@server_pids
        @server_pids = server_ports.map {|port| start_server(port) }
        sleep 5 # Wait for servers to start. Haxy, slow, error-prone :(
      end
      server_ports.map {|port| RemoteSandbox.new("http://localhost:#{port}/") }
    end
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
      f.puts "sandbox_files_root: #{::Rails.root}/ext/tmc-sandbox/output"
      f.puts "debug_log_file: debug.log"
    end
  end
  
end

RSpec.configure do |config|
  config.before :each do
    RemoteSandboxForTesting.init_stubs!
  end
  
  config.after :suite do
    RemoteSandboxForTesting.cleanup_after_all_tests!
  end
end

