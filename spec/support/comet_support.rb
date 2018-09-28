# frozen_string_literal: true

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
    'backend_key_for_tests'
  end

  def self.url
    "http://localhost:#{@port}/"
  end

  private

    def self.start!
      write_config_file
      raise 'Already running' if @started
      Dir.chdir TmcComet.get.path.parent do
        @pid = Process.spawn("./tmc-comet-server.sh #{config_file_path} > #{log_file} 2>&1", pgroup: true)
      end
      @started = true
      wait_for_http_access
    end

    def self.stop!
      if @pid
        # We started tmc-comet in a new process group. Kill entire process group.
        Process.kill('TERM', -@pid)
        Process.waitpid(@pid)
        @pid = nil
        @started = false
      end
    end

    def self.write_config_file
      File.open(config_file_path, 'wb') do |f|
        f.puts "fi.helsinki.cs.tmc.comet.backendKey = #{backend_key}"
        f.puts "fi.helsinki.cs.tmc.comet.allowedServers = http://localhost:#{Capybara.server_port}/"
        f.puts "fi.helsinki.cs.tmc.comet.server.httpPort = #{port}"
      end
    end

    def self.config_file_path
      "#{::Rails.root}/tmp/tests/tmc-comet-config"
    end

    def self.log_file
      "#{::Rails.root}/log/test_comet.log"
    end

    def self.wait_for_http_access
      30.times do
        sock = TCPSocket.open('localhost', port)
        sock.close
        return
      rescue StandardError
        sleep 0.5
      end
      raise "Failed to access tmc-comet. Please check #{log_file}."
    end
end

RSpec.configure do |config|
  config.after :suite do
    CometSupport.stop!
  end
end
