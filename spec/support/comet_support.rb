require 'tmc_comet'
require 'system_commands'
require 'socket'

module CometSupport
  def self.ensure_started!
    start! unless @started
  end

  def self.ensure_stopped!
    stop! if @started
  end

  def self.port
    @port ||= FreePorts.take_next
  end

  def self.backend_key
    "backend_key_for_tests"
  end

  def self.url
    "http://localhost:#{@port}/"
  end

private
  def self.start!
    write_config_file
    run_goal('jetty:stop jetty:deploy-war', false)
    @started = true
    wait_for_http_access
  end

  def self.stop!
    run_goal('jetty:stop', true)
  end

  def self.run_goal(goal, log_append)
    log_redir = log_append ? '>>' : '>'
    Dir.chdir TmcComet.get.path do
      SystemCommands.system! "mvn -Dfi.helsinki.cs.tmc.comet.configFile=#{config_file_path} -Djetty.port=#{port} #{goal} #{log_redir} #{log_file} 2>&1 &"
    end
  end

  def self.write_config_file
    File.open(config_file_path, 'wb') do |f|
      f.puts "fi.helsinki.cs.tmc.comet.backendKey = #{backend_key}"
      f.puts "fi.helsinki.cs.tmc.comet.allowedServers = http://localhost:#{Capybara.server_port}/"
    end
  end

  def self.config_file_path
    "#{::Rails::root}/tmp/tests/tmc-comet-config"
  end

  def self.log_file
    "#{::Rails::root}/log/test_comet.log"
  end

  def self.wait_for_http_access
    30.times do
      begin
        sock = TCPSocket.open('localhost', port)
        sock.close
        return
      rescue
        sleep 0.5
      end
    end
    raise "Failed to access tmc-comet. Please check #{log_file}."
  end
end

RSpec.configure do |config|
  config.after :suite do
    CometSupport.stop!
  end
end
