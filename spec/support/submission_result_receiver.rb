
# frozen_string_literal: true

# Receives incoming results from a remote sandbox during testing.
# Used by RemoteSandboxForTesting
class SubmissionResultReceiver
  def initialize
    @queue = Queue.new
    @port = FreePorts.take_next
    start_mimic_server!
  end

  def pop
    @queue.pop
  end

  def cleanup!
    Mimic.cleanup!
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
    "http://#{host_ip}:#{receiver_port}/results"
  end

  private

  def start_mimic_server!
    queue = @queue # put in closure, blocks below have different `self`
    Mimic.mimic(port: receiver_port, fork: true) do
      post('/results') do
        queue << params
        [200, {}, ['OK']]
      end
    end
  end
end
