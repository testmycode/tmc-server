
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

  def receiver_url
    "http://localhost:#{receiver_port}/results"
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
