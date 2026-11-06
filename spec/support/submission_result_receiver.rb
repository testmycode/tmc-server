# typed: false

# frozen_string_literal: true

require 'puma'
require 'puma/server'

# Receives incoming results from a remote sandbox during testing.
# Used by RemoteSandboxForTesting
class SubmissionResultReceiver
  def initialize
    @queue = Queue.new
    @port = 3000
    start_server!
  end

  def pop
    @queue.pop
  end

  def cleanup!
    @server&.stop(true)
    @server = nil
    @queue = nil
  end

  def receiver_port
    @port
  end

  def host_ip
    @addr ||= ENV['HOST'] ||= if ENV['CI']
                `ip addr|awk '/eth0/ && /inet/ {gsub(/\\/[0-9][0-9]/,""); print $2}'`.chomp
              else
                '127.0.0.1'
              end
  end

  def receiver_url
    "http://#{host_ip}:#{@port}/results"
  end

  private
    def start_server!
      queue = @queue
      app = lambda do |env|
        request = Rack::Request.new(env)
        next [404, {}, ['Not found']] unless request.post? && request.path_info == '/results'

        queue << request.params
        [200, {}, ['OK']]
      end

      @server = Puma::Server.new(app, nil, min_threads: 0, max_threads: 1, log_writer: Puma::LogWriter.null)
      # All interfaces, because in CI the sandbox reaches us at the container's IP.
      @server.add_tcp_listener('0.0.0.0', @port)
      @server.run
    end
end
