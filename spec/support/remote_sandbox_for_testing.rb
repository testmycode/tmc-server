require 'fileutils'

RSpec.configure do |config|
  server_pids = nil
  
  # We start two servers.
  # It's more reliable in case one is too slow to become ready again between tests.
  # Yes, it's theoretically still a race condition that should probably really be solved
  # e.g. by polling for the server(s) in an after :each.
  server_ports = [3002, 3003]
  
  config.before :each do
    RemoteSandbox.stub!(:all) do
      if !server_pids
        server_pids = server_ports.map do |port|
          instance_dir = "#{::Rails.root}/tmp/test-sandbox-server/#{port}"
          log_file = "#{instance_dir}/sandbox.log"
          FileUtils.mkdir_p File.dirname(instance_dir)
          FileUtils.rm_rf instance_dir
          FileUtils.cp_r "#{::Rails.root}/ext/tmc-sandbox/web", instance_dir
          
          File.open("#{instance_dir}/site.yml", "w") do |f|
            f.puts "sandbox_files_root: #{::Rails.root}/ext/tmc-sandbox"
          end
          
          Process.fork do
            begin
              $stdin.close
              $stdout.reopen(log_file, 'w')
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
        sleep 5 # Wait for servers to start. Haxy, slow, error-prone :(
      end
      server_ports.map {|port| RemoteSandbox.new("http://localhost:#{port}/") }
    end
  end
  
  config.after :all do
    if server_pids
      for server_pid in server_pids
        Process.kill("KILL", server_pid)
        Process.waitpid(server_pid)
      end
      server_pids = nil
    end
  end
end
