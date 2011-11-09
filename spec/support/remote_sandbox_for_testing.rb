RSpec.configure do |config|
  server_log_file = "#{::Rails.root}/tmp/test-tmc-sandbox.log"
  server_pid = nil
  
  config.before :each do
    RemoteSandbox.stub!(:all) do
      if !server_pid
        server_pid = Process.fork do
          begin
            $stdin.close
            $stdout.reopen(server_log_file, 'w')
            $stderr.reopen($stdout)
            Dir.chdir "#{::Rails.root}/ext/tmc-sandbox/web"
            ENV.delete 'BUNDLE_GEMFILE'
            Process.exec('bundle exec rackup --server webrick --port 3002')
          rescue
            puts e.class.to_s + ": " + e.message
          ensure
            exit!(1)
          end
        end
        sleep 1 # Wait for server to start. Haxy, slow, error-prone :(
      end
      [RemoteSandbox.new('http://localhost:3002/')]
    end
  end
  
  config.after :all do
    if server_pid
      Process.kill("KILL", server_pid)
      Process.waitpid(server_pid)
      server_pid = nil
    end
  end
end
